// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * HID driver for the ASUP1303 (Pixart 093a:3003) I2C-HID touchpad as fitted
 * to the ASUS Vivobook M1405YA.
 *
 * Why this driver exists
 * ----------------------
 * The panel is a Win8-style precision touchpad and hid-multitouch drives it
 * well enough to move a cursor, but its report descriptor is malformed in a
 * way that costs us palm rejection. Inside the Finger logical collection the
 * firmware emits:
 *
 *	05 0d	Usage Page (Digitizer)
 *	15 00	Logical Minimum (0)
 *	25 64	Logical Maximum (100)
 *	95 03	Report Count (3)
 *	c0	End Collection
 *
 * Three digitizer values scaled 0..100 are set up and then the collection is
 * closed without ever declaring a Usage or an Input item, so the parser drops
 * them. The values themselves are still transmitted, in three fields the
 * descriptor mislabels as vendor-defined (usage page 0xff00, usages 0x24,
 * 0x25 and 0x26). Because hid-multitouch never sees Width, Height or Tip
 * Pressure, libinput is left with only contact coordinates, which disables
 * both its pressure-based and its size-based palm heuristics -- the exact
 * failure the user hits when a resting palm and a moving finger are on the
 * pad at once.
 *
 * Rather than reimplement the descriptor fix as a kernel patch (which would
 * force a full kernel rebuild on every nixos-rebuild), this driver claims the
 * device outright and decodes report 0x04 itself. That also lets palm
 * rejection happen at the source: a contact whose reported size or pressure
 * exceeds a threshold is published as MT_TOOL_PALM, which libinput honours
 * natively.
 *
 * Report 0x04 layout (16 bytes including the report ID), derived from the
 * descriptor's field offsets:
 *
 *	byte  0		report ID (0x04)
 *	byte  1		bit 0	 Touch Valid (confidence)
 *			bit 1	 Tip Switch
 *			bits 2-3 padding
 *			bits 4-7 Contact Identifier
 *	bytes 2-3	X, little endian, 0..3996
 *	bytes 4-5	Y, little endian, 0..2242
 *	bytes 6-7	Scan Time, little endian, 100us units
 *	byte  8		Contact Count (contacts in this frame)
 *	byte  9		bit 0	 Button
 *			bits 1-7 vendor 0x24, 0..127
 *	bytes 10-13	vendor 0x25, little endian
 *	bytes 14-15	vendor 0x26, little endian
 *
 * One contact is transmitted per report; a frame is complete once
 * Contact Count contacts have been seen.
 */

#include <linux/bitops.h>
#include <linux/device.h>
#include <linux/hid.h>
#include <linux/input.h>
#include <linux/input/mt.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/types.h>
#include <linux/unaligned.h>

#define ASUP_VENDOR_ID		0x093a
#define ASUP_PRODUCT_ID		0x3003

#define ASUP_REPORT_ID_TOUCH	0x04
#define ASUP_TOUCH_REPORT_LEN	16

#define ASUP_MAX_CONTACTS	5

/* Logical maxima straight out of the report descriptor. */
#define ASUP_ABS_X_MAX		3996
#define ASUP_ABS_Y_MAX		2242

/*
 * Physical extent is declared as 1269 and 712 in 0.01cm units, i.e.
 * 126.9mm x 71.2mm. That yields ~31.5 units/mm on both axes; the input core
 * wants an integer, and 31 keeps libinput's millimetre maths honest enough
 * for its edge zones.
 */
#define ASUP_RES_X		31
#define ASUP_RES_Y		31

/* The undeclared digitizer fields are scaled 0..100 by the firmware. */
#define ASUP_LOGICAL_MAX	100

static unsigned int palm_size_threshold = 0;
module_param(palm_size_threshold, uint, 0644);
MODULE_PARM_DESC(palm_size_threshold,
		 "contact width above which a touch is reported as a palm (0..100, 0 disables)");

static unsigned int palm_pressure_threshold;
module_param(palm_pressure_threshold, uint, 0644);
MODULE_PARM_DESC(palm_pressure_threshold,
		 "contact pressure above which a touch is reported as a palm (0..100, 0 disables)");

static bool debug_reports;
module_param(debug_reports, bool, 0644);
MODULE_PARM_DESC(debug_reports,
		 "log the decoded fields of every touch report (very noisy)");

struct asup_drvdata {
	struct input_dev *input;
	/* Contacts still expected before the current frame is complete. */
	u8 contacts_remaining;
	bool frame_open;
};

static void asup_report_contact(struct asup_drvdata *td, u8 *data)
{
	struct input_dev *input = td->input;
	bool valid = data[1] & BIT(0);
	bool tip = data[1] & BIT(1);
	u8 id = (data[1] >> 4) & 0x0f;
	u16 x = get_unaligned_le16(&data[2]);
	u16 y = get_unaligned_le16(&data[4]);
	u8 v24 = data[9] >> 1;
	u32 v25 = get_unaligned_le32(&data[10]);
	u16 v26 = get_unaligned_le16(&data[14]);
	bool palm = false;
	int slot;

	if (debug_reports)
		pr_info("hid-asup1303: id=%u valid=%d tip=%d x=%u y=%u v24=%u v25=%u v26=%u\n",
			id, valid, tip, x, y, v24, v25, v26);

	slot = input_mt_get_slot_by_key(input, id);
	if (slot < 0)
		return;

	input_mt_slot(input, slot);

	/*
	 * A contact the firmware itself flags as not valid is its own palm
	 * signal; drop it before any of our thresholds get a say.
	 */
	if (!tip || !valid) {
		input_mt_report_slot_inactive(input);
		return;
	}

	if (palm_size_threshold && v24 >= palm_size_threshold)
		palm = true;
	if (palm_pressure_threshold && v26 >= palm_pressure_threshold)
		palm = true;

	input_mt_report_slot_state(input, palm ? MT_TOOL_PALM : MT_TOOL_FINGER,
				   true);
	input_report_abs(input, ABS_MT_POSITION_X, x);
	input_report_abs(input, ABS_MT_POSITION_Y, y);
	input_report_abs(input, ABS_MT_TOUCH_MAJOR, v24);
	input_report_abs(input, ABS_MT_PRESSURE, v26);
}

static int asup_raw_event(struct hid_device *hdev, struct hid_report *report,
			  u8 *data, int size)
{
	struct asup_drvdata *td = hid_get_drvdata(hdev);
	u8 contact_count;

	if (!td || !td->input)
		return 0;

	if (data[0] != ASUP_REPORT_ID_TOUCH || size < ASUP_TOUCH_REPORT_LEN)
		return 0;

	contact_count = data[8];

	/*
	 * Contact Count is only meaningful on the first report of a frame;
	 * subsequent reports in the same frame repeat it or carry zero
	 * depending on firmware mood, so latch it once and count down.
	 */
	if (!td->frame_open) {
		if (contact_count == 0 || contact_count > ASUP_MAX_CONTACTS)
			contact_count = 1;
		td->contacts_remaining = contact_count;
		td->frame_open = true;
	}

	asup_report_contact(td, data);

	if (td->contacts_remaining)
		td->contacts_remaining--;

	if (!td->contacts_remaining) {
		input_report_key(td->input, BTN_LEFT, data[9] & BIT(0));
		input_mt_sync_frame(td->input);
		input_sync(td->input);
		td->frame_open = false;
	}

	/* Report consumed; keep hid-input out of it. */
	return 1;
}

/*
 * Suppress hid-input's default mapping for everything in the touchpad
 * collection. We publish the axes ourselves from raw_event; letting the
 * generic path also map X/Y -- and the three mislabelled vendor fields --
 * would leave the input node carrying a second, bogus set of axes.
 */
static int asup_input_mapping(struct hid_device *hdev, struct hid_input *hi,
			      struct hid_field *field, struct hid_usage *usage,
			      unsigned long **bit, int *max)
{
	if (field->application == HID_DG_TOUCHPAD ||
	    field->application == HID_DG_TOUCHSCREEN)
		return -1;

	return 0;
}

static int asup_input_configured(struct hid_device *hdev, struct hid_input *hi)
{
	struct asup_drvdata *td = hid_get_drvdata(hdev);
	struct input_dev *input = hi->input;
	int ret;

	/* Only the touchpad application collection interests us. */
	if (hi->report->id != ASUP_REPORT_ID_TOUCH)
		return 0;

	input->name = "ASUP1303 Touchpad";

	set_bit(EV_ABS, input->evbit);
	set_bit(EV_KEY, input->evbit);
	set_bit(BTN_LEFT, input->keybit);
	set_bit(INPUT_PROP_POINTER, input->propbit);
	set_bit(INPUT_PROP_BUTTONPAD, input->propbit);

	input_set_abs_params(input, ABS_MT_POSITION_X, 0, ASUP_ABS_X_MAX, 0, 0);
	input_set_abs_params(input, ABS_MT_POSITION_Y, 0, ASUP_ABS_Y_MAX, 0, 0);
	input_abs_set_res(input, ABS_MT_POSITION_X, ASUP_RES_X);
	input_abs_set_res(input, ABS_MT_POSITION_Y, ASUP_RES_Y);

	/*
	 * The axes the broken descriptor cost us. Exposing them is the whole
	 * point of the driver: libinput turns pressure and touch-major into
	 * palm and thumb rejection.
	 */
	input_set_abs_params(input, ABS_MT_TOUCH_MAJOR, 0, ASUP_LOGICAL_MAX,
			     0, 0);
	input_set_abs_params(input, ABS_MT_PRESSURE, 0, ASUP_LOGICAL_MAX, 0, 0);

	ret = input_mt_init_slots(input, ASUP_MAX_CONTACTS,
				  INPUT_MT_POINTER | INPUT_MT_DROP_UNUSED);
	if (ret) {
		hid_err(hdev, "failed to init MT slots: %d\n", ret);
		return ret;
	}

	td->input = input;
	return 0;
}

static int asup_probe(struct hid_device *hdev, const struct hid_device_id *id)
{
	struct asup_drvdata *td;
	int ret;

	td = devm_kzalloc(&hdev->dev, sizeof(*td), GFP_KERNEL);
	if (!td)
		return -ENOMEM;

	hid_set_drvdata(hdev, td);

	ret = hid_parse(hdev);
	if (ret) {
		hid_err(hdev, "parse failed: %d\n", ret);
		return ret;
	}

	ret = hid_hw_start(hdev, HID_CONNECT_DEFAULT);
	if (ret) {
		hid_err(hdev, "hw start failed: %d\n", ret);
		return ret;
	}

	return 0;
}

static const struct hid_device_id asup_devices[] = {
	{ HID_DEVICE(BUS_I2C, HID_GROUP_ANY, ASUP_VENDOR_ID, ASUP_PRODUCT_ID) },
	{ HID_DEVICE(BUS_I2C, HID_GROUP_MULTITOUCH_WIN_8, ASUP_VENDOR_ID,
		     ASUP_PRODUCT_ID) },
	{ }
};
MODULE_DEVICE_TABLE(hid, asup_devices);

static struct hid_driver asup_driver = {
	.name			= "hid-asup1303",
	.id_table		= asup_devices,
	.probe			= asup_probe,
	.raw_event		= asup_raw_event,
	.input_mapping		= asup_input_mapping,
	.input_configured	= asup_input_configured,
};
module_hid_driver(asup_driver);

MODULE_DESCRIPTION("ASUP1303 (Pixart 093a:3003) touchpad driver with palm rejection");
MODULE_LICENSE("GPL");
