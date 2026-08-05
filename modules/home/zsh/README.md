# zsh

`default.nix` is a NixOS/Darwin wrapper around the reusable `./hm.nix`
home-manager module, so the same zsh config can be imported directly by
single-user home-manager (nix-on-droid / `honor`). See `../README.md`.

## aliases.nix

**Android mirroring.** The scrcpy alias mirrors a device borderless at the same
height as iPhone Mirroring's largest zoom (898px window). scrcpy cannot draw
rounded corners or a phone frame, so borderless is the closest "phone-screen"
look. Width follows the device aspect ratio, and `command` skips the alias to
avoid a recursion loop.
