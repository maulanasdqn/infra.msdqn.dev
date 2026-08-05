# vivobook — Asus Vivobook laptop

NixOS workstation.

## FnLock default

The top row acts as media/action keys (volume, brightness, …) **without**
holding Fn; Fn is then needed for F1–F12.

`asus_wmi`'s `fnlock_default` defaults to `Y` (F-keys primary), so it is set to
`0` to make the printed media functions primary instead. Runtime toggle is
**Fn+Esc**.

## Do not re-add the ACPI OSI override

An `acpi_osi="Windows 2020"` kernel parameter was removed. It changed Asus DSDT
device enumeration and **hung early boot** at *"Starting Virtual Console"*. If
you are tempted to add it for some ACPI quirk, expect an unbootable machine.

## Performance

Governor tuning is deliberately left alone — see
`../../../modules/nixos/README.md`. This machine uses `amd-pstate-epp` in active
mode with `balance_performance`, which is already correct for Zen3 laptops.
