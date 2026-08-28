# Android (nix-on-droid)

Shared nix-on-droid base: packages, the nix-env shim, timezone and
stateVersion. Host-specific config lives in subdirectories.

## Two kinds of Android host

Not every phone here is a nix-on-droid host, and `default.nix` only applies to
the ones that are.

| Host      | Device                | Nix runs             | Imports `default.nix` |
| --------- | --------------------- | -------------------- | --------------------- |
| `honor`   | HONOR X9c (BRP-NX1)   | nix-on-droid / proot | yes                   |
| `poco-f3` | POCO F3 (`alioth`)    | natively at `/nix`   | **no**                |

`honor` has a permanently locked bootloader, so proot is the only option.
`poco-f3` is unlocked and rooted, so `/nix` is a real bind mount and Nix runs
without proot — which also frees it from the 25.11 pinning `honor` needs, since
the glibc 2.42 breakage is a proot bug.

Because this file sets nix-on-droid-only options (`environment.packages`,
`terminal.font`, `system.stateVersion`), `poco-f3` cannot import it; it is a
standalone `homeManagerConfiguration` under `nix.homeConfigurations` instead of
`nixOnDroidConfigurations`. See `poco-f3/README.md`.

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
