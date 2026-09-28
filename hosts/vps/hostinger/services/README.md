# Hostinger VPS — services

Per-app modules for the Hostinger box (`72.62.125.38`).

The KYA apps (field-quote, sales-reporting, bond-closeout, bill-pay,
entity-license-renewal, field-checklist, bid-intake) moved off this box on
2026-09-28 to the `kya-prod` DigitalOcean droplet (`159.203.160.64`, Torchstone
Global team). They run there as Docker Compose projects under `/opt/kya/<app>`,
outside this repo.

## Parallax proxy

| Module | Service | Port | Protocol |
|---|---|---|---|
| `parallax.nix` | Parallax SOCKS5/HTTP proxy | 1080 | SOCKS5 + HTTP CONNECT + HTTP forward |

Native Rust binary built from `pkgs/parallax` via `rustPlatform.buildRustPackage`,
fetched from `github:maulanasdqn/parallax`. Runs as a hardened `DynamicUser`
systemd service (no container, no Postgres, no nginx). Auto-detects SOCKS5 vs
HTTP per connection on the same port. No authentication configured by default;
set `PROXY_USER` and `PROXY_PASS` in the environment block to enable.
