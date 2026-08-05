# Modules

Reusable configuration, grouped by platform.

| Directory | Scope |
|---|---|
| `darwin/` | macOS (nix-darwin) |
| `nixos/` | NixOS hosts |
| `home/` | home-manager, shared across platforms |

`nix.nix` holds common Nix daemon settings applied everywhere.

Several `home/` modules use a two-file wrapper pattern so the same config works
under full NixOS/Darwin **and** standalone single-user home-manager on
nix-on-droid. See `home/README.md`.
