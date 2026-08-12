# Raspberry Pi — Home DNS Server

Raspberry Pi running AdGuard Home as a network-wide DNS ad blocker.

## Architecture

- **Platform**: `aarch64-linux` (Raspberry Pi 4/5)
- **OS**: NixOS (SD card image via `sd-image-aarch64`)
- **Primary service**: AdGuard Home (DNS-level ad/tracker blocking)
- **Network**: DHCP by default, discoverable via mDNS (`raspi.local`)

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

## Pointing Your Network to the Pi

**Router-level** (recommended — blocks ads for all devices):
- Router admin → DNS settings → set primary DNS to Pi's IP
- Set secondary DNS to `1.1.1.1` as fallback

**Per-device**: set DNS server to the Pi's IP on each device.

## Changing Networks (Office → Home)

The Pi uses DHCP, so it gets an IP automatically on any network. Avahi/mDNS
is enabled, so `raspi.local` resolves regardless of which network or IP it
gets. Just plug in Ethernet and SSH to `raspi.local`.

## Deployed Services

| Port | Service |
|------|---------|
| 22 | SSH |
| 53 | DNS (AdGuard Home) |
| 80 | AdGuard Home web UI |
| 3000 | AdGuard Home initial setup wizard |

## Updating

From the infra repo on any machine:

```bash
# Build on Pi (recommended for aarch64)
clan machines update raspi --build-host ms@raspi.local --target-host ms@raspi.local

# Or push config and let git-sync pick it up (if enabled)
git push
```

## Hardware Notes

- `hardware.nix` uses the standard `sd-image-aarch64` module
- `boot.loader.generic-extlinux-compatible` is used instead of systemd-boot
  (which doesn't work on Pi)
- `libraspberrypi` is included for `vcgencmd` (temperature, throttling status)
- zram swap is enabled at 50% of RAM to compensate for limited memory
