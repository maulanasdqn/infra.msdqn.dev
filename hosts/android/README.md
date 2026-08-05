# Android (nix-on-droid)

Shared nix-on-droid base: packages, the nix-env shim, timezone and
stateVersion. Host-specific config lives in subdirectories (`honor/`).

## Bootstrap essentials only

This layer stays minimal. Richer CLI tooling comes from
`../../modules/home/packages/cli.nix`, which host home configs import — so the
phone gets the same tools as the desktop without duplicating the list here.

Included at this level: `clear`, `tput` and terminfo (needed by
zsh/starship/TUIs), plus JetBrainsMono Nerd Font for the terminal app. Same
family as the desktop/hyprland setup; the **Mono** variant keeps icon glyphs
cell-width.

## Historical note

A previous `fixNixEnvPty` activation hack wrapped `nix-env` to work around a PTY
issue. It is gone — see `honor/README.md` for the pinning that replaced the need
for it.
