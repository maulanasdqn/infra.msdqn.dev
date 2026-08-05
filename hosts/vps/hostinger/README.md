# Hostinger VPS (`msdqn`)

Production box at `72.62.125.38`. Runs the four KYA business apps behind nginx.
Per-app detail lives in [`services/README.md`](services/README.md).

## Layout

| File | Purpose |
|---|---|
| `default.nix` | Host entry point — imports, nginx, ACME, networking, swap |
| `hardware.nix` | Hardware/boot configuration |
| `disk-config.nix` | disko layout |
| `services/` | One module per app |

## Networking

Static IPv4 on `ens18`, /24, explicit default gateway. DNS is `8.8.8.8` and
`1.1.1.1`. Only 80 and 443 are opened here; 22 comes from `profiles/server.nix`.

A 2 GB `/swapfile` is configured on top of the zram swap from the server profile.

## nginx

NixOS nginx is the sole reverse proxy and static file server. The host sets the
`recommended*` options; each app module contributes its own vhost. A
`securityHeaders` snippet (`X-Frame-Options`, `X-Content-Type-Options`,
`X-XSS-Protection`, `Referrer-Policy`) is defined in `default.nix` for vhosts
that want it.

ACME/Let's Encrypt is enabled with the `acmeEmail` argument.

## Deploying

Built **on the VPS** — a Mac cannot cross-compile to `x86_64-linux`:

```sh
clan machines update hostinger \
  --build-host root@72.62.125.38 \
  --target-host root@72.62.125.38
```

Every switch costs ~2 minutes of 502s across all four apps; see the services
README for why.

## Removed subsystems

**SIEM/SOAR (removed).** fluent-bit, the wazuh agent, suricata and the aysiem
heartbeat all ran here and shipped to `ingest-aysiem.msdqn.dev`. All are gone,
along with the `extraHosts` entry that resolved that name.

**auditd (removed).** `profiles/server.nix` carried
`-a exit,always -F arch=b64 -S execve`, logging *every* process execution on the
box at five records per exec. NixOS emits an `auditd.conf` with no
`max_log_file`, `num_logs` or `max_log_file_action`, so `/var/log/audit/audit.log`
grew unbounded — it reached **68 GB**, about two thirds of the disk. Its only
consumers were fluent-bit and wazuh, so it went with them.

If you ever reinstate audit logging, set the rotation keys first.

Note that `auditd` sets `RefuseManualStop`, so a switch cannot stop it. Deleting
its log while it is running frees nothing — the daemon holds the inode open, and
`df` will not move until the process is killed directly. Check `/proc/*/fd` for
`(deleted)` handles before believing space was reclaimed.

**rkm-backend (excluded).** A Rust app; kept out of the clan VPS build so no
cargo compile happens on the box. Its `api.rajawalikaryamulya.co.id` vhost is
commented out in `default.nix` and must be re-enabled together with the module.

**Backups (disabled).** See the services README.

## Retained

`fail2ban` stays — it is active blocking, not SIEM/SOAR. Six jails are
configured in `profiles/server.nix`.
