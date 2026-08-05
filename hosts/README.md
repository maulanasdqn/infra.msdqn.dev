# Hosts

One directory per machine.

| Path | Kind |
|---|---|
| `vps/hostinger/` | Production VPS — the four KYA apps |
| `vps/digitalocean/` | DigitalOcean VPS |
| `workstation/vivobook/` | NixOS laptop (Asus) |
| `workstation/pc/` | NixOS desktop — hardware config still a placeholder |
| `android/honor/` | nix-on-droid on HONOR X9c |

Darwin hosts are defined directly in `flake.nix` rather than here; see the root
README for the `enableAggressiveTweaks` split between the single-owner MacBook
and the shared Mac mini.

Each host imports a profile from `../profiles/` rather than restating policy.
