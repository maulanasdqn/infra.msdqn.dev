# AdGuard Home Module

DNS-level ad and tracker blocking via AdGuard Home.

## What It Configures

- **Upstream DNS**: Cloudflare DoH + Google DoH + Cloudflare DoT (encrypted)
- **Bootstrap DNS**: `1.1.1.1`, `8.8.8.8`, `9.9.9.9` (for resolving DoH hostnames)
- **DNSSEC**: enabled
- **Cache**: 10MB optimistic cache, TTL 5min–24h
- **Rate limit**: 300 queries/sec (protects against DNS amplification)

## Blocklists

Eight curated lists enabled by default:

| ID | List |
|----|------|
| 1 | AdGuard DNS filter |
| 2 | AdAway Default Blocklist |
| 3 | Peter Lowe - Adservers |
| 4 | Dan Pollock's List |
| 6 | Dandelion Sprout - Anti-Malware List |
| 7 | Perflyst - Smart-TV Blocklist |
| 23 | Game Console Adblock List |
| 33 | Steven Black - Unified hosts |

## Mutable Settings

`mutableSettings = true` means AdGuard Home's web UI changes persist across
restarts. The Nix config provides the initial/default values, but once the
web wizard is completed and you make changes in the UI, those take precedence.

## First-Time Setup

After deployment, open `http://<host>:3000` to complete the setup wizard
(set admin credentials). The DNS and filter settings are pre-populated.
