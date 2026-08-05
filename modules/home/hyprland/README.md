# Hyprland

Wayland compositor config for the Linux workstations.

| File | Role |
|---|---|
| `default.nix` | Compositor, keybinds, rules |
| `theme.nix` | Colours and wallpaper |
| `hypridle.nix` | Idle behaviour |

## Caffeine toggle

`hypridle` is the only thing driving auto-lock, DPMS-off and suspend, so
stopping the service means the screen never locks or sleeps on idle. That is
exactly what the caffeine toggle does — flip a "never lock/sleep" mode on or
off by starting/stopping `hypridle`.

Manual locking is unaffected: `$mod+X` (hyprlock) and the lid switch still work.

## Wallpaper

`theme.nix` has a commented-out `home.file` entry for
`~/.config/hypr/wallpaper.jpg`. **TODO:** add `wallpaper.jpg` to the repo root
to enable it.
