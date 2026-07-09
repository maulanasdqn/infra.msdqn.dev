# HONOR X9c debloat

adb-based debloat for the `honor` phone (see `../default.nix`). Disables MagicOS
bloatware without root or data loss, and is fully reversible.

- **Device:** HONOR X9c — model `BRP-NX1`, codename `HNBRP-Q1`, Qualcomm SoC
  (`ro.board.platform: parrot`), running MagicOS 10 / Android 16.
- **Method:** `pm disable-user --user 0 <pkg>` over adb. Reversible with
  `pm enable <pkg>`. Nothing is uninstalled; no data is touched.

## Usage

Connect the phone (USB debugging on) and:

```sh
./debloat.sh disable   # apply the debloat (disable every pkg in packages.txt)
./debloat.sh enable    # revert (re-enable everything)
./debloat.sh status    # show current enabled/disabled/absent state per pkg
```

Edit `packages.txt` to add/remove packages. Lines are `pkg  # comment`; blanks
and `#` lines are ignored.

## Gotcha: PDF "Unsupported File Type"

`com.hihonor.hnoffice` is the Yozo/WPS render backend
(`com.yozo.pdf.multiprocess.PDFPhoneActivity0`) that Honor Files / `fileservice`
preview delegates to. If it is disabled, **every PDF/Office open throws
"Unsupported File Type."** It is deliberately NOT in `packages.txt`, and it was
found disabled on this device — re-enable it if PDFs break:

```sh
adb shell pm list packages -d com.hihonor.hnoffice   # if listed, it's disabled
adb shell pm enable com.hihonor.hnoffice
```

## Bootloader / custom ROM

Not possible on this device. Bootloader is permanently locked
(`ro.boot.flash.locked=1`, `vbmeta.device_state=locked`, no OEM-unlock toggle),
Honor issues no unlock codes, PotatoNV is Kirin-only (this is Qualcomm), and EDL
firehose is authenticated. Debloat + a custom launcher is the closest-to-vanilla
route. See `honor-x9c-debloat` in Claude memory for the full rationale.
