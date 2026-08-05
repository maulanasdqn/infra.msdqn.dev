# home-manager modules

Shared user environment. Several modules follow a deliberate **two-file
pattern**:

- `hm.nix` — the reusable, mobile-safe home-manager module
- `default.nix` — a NixOS/Darwin wrapper that mounts `hm.nix` under the user's
  home-manager and may add desktop-only extras

This exists so nix-on-droid (`honor`) can import `hm.nix` **directly** as a
single-user home-manager config, without dragging in anything desktop-specific.
`zsh/`, `starship/` and `neovim/` all use it.

| Directory | Notes |
|---|---|
| `neovim/` | Editor + LSP; heaviest use of the split |
| `zsh/`, `starship/` | Wrapper + reusable pair |
| `packages/` | `cli.nix` shared with mobile, `nixos.nix` GUI-only |
| `hyprland/` | Linux desktop |
| `ssh/`, `git/`, `docker/` | Small, self-contained |

## Manual disabled

`darwin.nix` skips the home-configuration man page for the same reason as the
nix-darwin manual: its `options.json` comes from nixpkgs' `nixosOptionsDoc`,
which references the nixpkgs source path without string context on current
nixpkgs-unstable and emits a build-time warning.

## git

`home.stateVersion` is < 25.05, so the git module still defaults
`signing.format` to `"openpgp"`. It is set explicitly to silence the deprecation
warning — no signing key is configured, so the setting is inert.

## docker

Colima does **not** start at login: a VM's worth of RAM per session is wasteful.
Start on demand with `colima-up`. An idle auto-stop agent complements this.

## ssh

`authorized_keys` is intentionally **not** managed here. home-manager would
write it as a `/nix/store` symlink, which sshd's `StrictModes` rejects with
*"bad ownership or modes for directory /nix/store"*. Inbound keys are set via
`users.users.<name>.openssh.authorizedKeys.keys` in
`../darwin/default.nix` instead.
