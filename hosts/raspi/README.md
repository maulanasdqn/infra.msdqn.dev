# Raspberry Pi — Home DNS Server

Raspberry Pi running AdGuard Home as a network-wide DNS ad blocker.

## Architecture

- **Platform**: `aarch64-linux` (Raspberry Pi 4/5)
- **OS**: NixOS (SD card image via `sd-image-aarch64`)
- **Primary service**: AdGuard Home (DNS-level ad/tracker blocking)
- **Static IP**: `192.168.100.139/24` on the Huawei ONT subnet
- **Gateway**: `192.168.100.1` (Huawei ONT)
- **Discoverable via**: mDNS (`raspi.local`)

## Initial Flash

Build the SD card image from a machine with `aarch64-linux` support (or use
QEMU binfmt):

```bash
nix build .#nixosConfigurations.raspi.config.system.build.sdImage
```

The image lands in `result/sd-image/`. Flash it:

```bash
# macOS
sudo dd if=result/sd-image/nixos-sd-image-*.img of=/dev/rdiskN bs=4m
# or use Raspberry Pi Imager → "Use custom" → select the .img
```

## First Boot

1. Insert SD card into Pi, connect Ethernet, power on
2. Wait ~2 minutes for first boot + NixOS activation
3. Find it: `ping raspi.local` or check your router's DHCP leases
4. SSH in: `ssh ms@raspi.local`

## AdGuard Home Setup

On first boot, AdGuard Home listens on port 3000 for initial setup:

1. Open `http://raspi.local:3000`
2. Set admin username and password
3. Set listen interface to all interfaces (`0.0.0.0`)
4. Upstream DNS, blocklists, and DNSSEC are pre-configured by the Nix module

## Network Topology

```
Huawei ONT (192.168.100.1) ─── PPPoE + DHCP 192.168.100.x
  └── MikroTik hEX (WAN: 192.168.100.117, LAN: 192.168.88.1)
        ├── Raspberry Pi (192.168.88.10) ← DNS server (AdGuard Home)
        └── Switch → 3× Ruijie APs (mesh) + all devices
```

The MikroTik side is configured by hand on the router, not from this repo:

- **DHCP** hands out `dns-server=192.168.88.10,192.168.88.1` — AdGuard first,
  the router second.
- **`/ip dns servers=192.168.88.10`** — the router's own resolver forwards to
  AdGuard.
- **dst-nat "force DNS to AdGuard" (udp + tcp)** redirects every LAN port-53
  query to the Pi, so devices with hardcoded DNS (Chromecast, `8.8.8.8`) are
  still filtered. Two srcnat "hairpin" rules masquerade the redirected traffic.

### DNS failover

A netwatch probe (`AdGuard DNS failover`, type `dns`, resolves `google.com`
via `192.168.88.10` every 15 s) keeps the house online when AdGuard dies:

- **down** — disables the force-DNS dst-nat rules, sets the router's DNS to
  AdGuard DNS public (`94.140.14.14,94.140.15.15`) and flushes its cache.
  Clients time out on the Pi, fall back to `192.168.88.1`, and stay ad-blocked
  through AdGuard's own resolvers (no local blocklists or custom rules).
- **up** — sets the router back to `192.168.88.10`, re-enables the dst-nat
  rules and flushes the cache.

The second DHCP DNS entry is what makes this work. With only `192.168.88.10`
handed out, clients talk to the Pi directly over L2, never touch the router,
and the failover changes nothing for them. Clients only pick up the second
server on their next lease (12 h lease time).

Tested 2026-10-21: stopping `adguardhome` flipped netwatch to `down` within
~10 s and HTTPS from a renewed client kept working (200 in 0.38 s); starting it
flipped back to `up` with ad blocking restored.

## Power

The Pi logs `hwmon hwmon1: Undervoltage detected!` every few minutes (97 times
in one 26 h boot) with no USB storage attached. The supply or cable cannot hold
5.1 V under load. Use the official 5.1 V / 3 A USB-C supply with a short cable;
brownouts are a likely cause of hard hangs and SD-card corruption.

## Deployed Services

| Port | Service |
|------|---------|
| 22 | SSH |
| 53 | DNS (AdGuard Home) |
| 80 | AdGuard Home web UI |
| 1080 | Parallax proxy (`services/parallax.nix`) |
| 3000 | AdGuard Home initial setup wizard |

## Updating

From the infra repo on any machine:

```bash
# Build on Pi (recommended for aarch64)
clan machines update raspi --build-host ms@raspi.local --target-host ms@raspi.local

# Or push config and let git-sync pick it up (if enabled)
git push
```

`system.autoUpgrade` is **disabled**. Deploy only with `clan machines update`
from a workstation.

The nightly 04:00 upgrade switched configuration from inside
`nixos-upgrade.service`. On 2026-10-20 and 2026-10-21 that switch stopped
AdGuard, timesyncd and the name-lookup targets, then died with
`Failed to process dbus messages while waiting for jobs ... disconnected from
D-Bus?`. The stopped units were never started again, so the Pi stayed up while
DNS was dead for the whole house until someone power-cycled it (14 h on
2026-10-20, ~17 h on 2026-10-21).

`services.zfs.autoScrub` is forced off. clan's core ZFS module enables it on
every machine, but the Pi has no ZFS pools, so the weekly scrub fails with
`missing pool name argument`.

## Performance Tuning

The Pi runs from an SD card, so most tuning reduces write pressure and keeps
hot data in RAM:

- **`noatime`** on `/` — skips access-time updates on every read, the single
  biggest SD card write reduction
- **`boot.tmp.useTmpfs`** — `/tmp` lives in RAM, not on the card
- **I/O scheduler `none`** — SD cards have no seek time; the default `mq-deadline`
  adds overhead for nothing (set via udev rule on `mmcblk*`)
- **`vm.dirty_ratio=40`, `vm.dirty_background_ratio=10`** — batches writes into
  fewer, larger flushes instead of many small ones
- **`vm.vfs_cache_pressure=50`** — keeps dentry/inode caches longer, good for a
  DNS server that stats the same files repeatedly
- **`net.core.somaxconn=4096`** — raises the listen backlog for AdGuard and
  Parallax
- **Nix parallelism** — `max-jobs=auto`, `cores=4`, plus `max-substitution-jobs`
  and `http-connections` to speed up `nix build` and fetches

## Hardware Notes

- `hardware.nix` uses the standard `sd-image-aarch64` module
- `boot.loader.generic-extlinux-compatible` is used instead of systemd-boot
  (which doesn't work on Pi)
- `libraspberrypi` is included for `vcgencmd` (temperature, throttling status)
- zram swap is enabled at 50% of RAM to compensate for limited memory
