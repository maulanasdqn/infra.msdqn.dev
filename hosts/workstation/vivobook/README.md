# vivobook — Asus Vivobook laptop

NixOS workstation.

## FnLock default

The top row acts as media/action keys (volume, brightness, …) **without**
holding Fn; Fn is then needed for F1–F12.

`asus_wmi`'s `fnlock_default` defaults to `Y` (F-keys primary), so it is set to
`0` to make the printed media functions primary instead. Runtime toggle is
**Fn+Esc**.

## GNOME extensions

This is the only GNOME host in the repo — everything else runs Hyprland, so
`programs.hyprland.enable` is forced off here and the desktop config lives in
this file rather than in a shared module.

Caffeine (`caffeine@patapon.info`) keeps the screen awake on demand from a
panel toggle. A GNOME extension needs **two** things and neither implies the
other:

- the package in `environment.systemPackages`, which puts it under
  `/run/current-system/sw/share/gnome-shell/extensions/` where gnome-shell
  looks for it;
- its UUID listed in `org/gnome/shell` `enabled-extensions` via dconf, which is
  what actually switches it on.

`disable-user-extensions = false` is set alongside it because that single key
mutes every extension at once regardless of the enabled list, and GNOME flips
it itself after a shell crash.

Adding another extension means appending its UUID to the same
`enabled-extensions` list — declaring a second `org/gnome/shell` block would
clash rather than merge. Read the UUID off the package instead of guessing it:

```sh
nix eval --raw ".#nixosConfigurations.vivobook.pkgs.gnomeExtensions.<name>.extensionUuid"
```

Extensions are pinned to the GNOME release in nixpkgs (currently gnome-shell
50), so a version an extension does not support yet makes it silently fail to
load rather than error at build time.

## Do not re-add the ACPI OSI override

An `acpi_osi="Windows 2020"` kernel parameter was removed. It changed Asus DSDT
device enumeration and **hung early boot** at *"Starting Virtual Console"*. If
you are tempted to add it for some ACPI quirk, expect an unbootable machine.

## Performance

Governor tuning is deliberately left alone — see
`../../../modules/nixos/README.md`. This machine uses `amd-pstate-epp` in active
mode with `balance_performance`, which is already correct for Zen3 laptops.
