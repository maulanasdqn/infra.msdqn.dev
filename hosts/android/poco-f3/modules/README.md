# poco-f3 Magisk modules

Everything this phone needs on top of stock crDroid, built by Nix instead of
by hand. `nix build` produces the flashable zips; `nix run .#poco-f3-deploy`
pushes, installs and reboots.

| Module      | What it does                                                  |
| ----------- | ------------------------------------------------------------- |
| `nixbind`   | Creates `/nix` and bind-mounts the store so Nix runs natively  |
| `hardening` | Kernel sysctls, privacy defaults, idle radios, auto-reboot     |
| `adblock`   | System-wide ad/tracker blocking via `/system/etc/hosts`        |
| `nixenter`  | `nix-enter` / `ne` on PATH: root shell with Nix, from any term  |
| `sshd`      | Native-nix OpenSSH on `127.0.0.1:8022` for a real terminal     |
| `stealth`   | Spoofs boot state, build type and detection-prone props        |
| `iossounds` | Replaces UI sounds, notifications, ringtones and alarms        |

## Building

```sh
nix build .#poco-f3-nixbind          # pure, no extra setup
nix build .#poco-f3-modules --impure # everything available
nix run  .#poco-f3-deploy            # build + push + install + reboot
```

`poco-f3-deploy` refuses to run unless `ro.product.device` is `alioth` and
Magisk `su` works, so it cannot fire at the wrong phone.

## Why iossounds needs --impure and an env var

**Apple's audio is never committed to this repository, because it is public.**
Shipping 141 iOS sound files here would be redistributing Apple's copyrighted
work. Only the recipe lives in git.

The sounds are read at build time from a local Xcode iOS simulator runtime,
which is licensed to you as part of your own Xcode install:

```sh
export IOS_RUNTIME_ROOT="/Library/Developer/CoreSimulator/Volumes/iOS_24A5380g/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 27.0.simruntime/Contents/Resources/RuntimeRoot"
nix build .#poco-f3-iossounds --impure
```

Find yours with `xcrun simctl runtime list -j`; newer Xcode mounts runtimes as
APFS volumes under `/Library/Developer/CoreSimulator/Volumes/` rather than as
`.simruntime` bundles, and `simctl` reports the *asset* path, not the mount.

`--impure` is required because `builtins.getEnv` and reading a path outside the
store are both impure. Without `IOS_RUNTIME_ROOT` set, the `poco-f3-iossounds`
output simply is not offered and `poco-f3-modules` contains `nixbind` alone.

Only three subdirectories are imported (~76 MB), never the whole
`RuntimeRoot` — that is **17 GB** and would be copied into the store wholesale.

## Sound conversion notes

Android wants Ogg Vorbis; iOS ships CAF and M4R, so everything is transcoded.
Two things are easy to get wrong:

- **Levels.** Apple ships these far below full scale — `Tock` peaks at −8.5 dB
  and *averages* −24.7 dB, `keyboard_press_normal` averages −43.9 dB — and
  Android replays UI effects quietly on top of that. A straight transcode is
  audible on a Mac and inaudible on the phone. Every file is peak-normalised to
  −1 dBFS, which lifts `KeypressStandard` by roughly 31 dB.
- **Haptics.** `.m4r` tones carry `ahap` haptic data streams alongside the
  audio. ffmpeg aborts trying to transcode those, so `-map 0:a:0` is required.

`AlertTones` also nests under `Classic/`, `Modern/` and `EncoreInfinitum/` and
reuses the same tone names across them, so the variant folder is kept in the
output filename or the files overwrite each other.

## Mapping choices

`Effect_Tick` is the sound Android fires on *every* tap, including back and
menu navigation. It maps to iOS `key_press_modifier` — the deeper thunk the iOS
keyboard makes for Return/Done/Shift, rather than the thinner `Tock`
picker-wheel tick or the very short `key_press_click`.

Worth knowing: **iOS itself plays no sound for UI navigation.** Tapping a back
button or a Settings row on a real iPhone is silent; iOS only sounds on
keyboard presses, lock, screenshot and notifications. So an audible tap is
deliberately *not* authentic — it keeps Android's feedback model with iOS
timbre. Removing `Effect_Tick` from the map is the authentic option.

## hardening

`post-fs-data.sh` applies kernel sysctls; `service.sh` applies framework
settings at `late_start` and then runs an idle watcher.

crDroid already ships the compile-time kernel hardening that matters —
`RANDOMIZE_BASE` (KASLR), `HARDENED_USERCOPY`, `SLAB_FREELIST_RANDOM` and
`_HARDENED`, `STACKPROTECTOR_STRONG`, `STRICT_KERNEL_RWX`, `INIT_ON_ALLOC`,
`BUG_ON_DATA_CORRUPTION`. Rebuilding the kernel would only add `INIT_ON_FREE`,
`HARDENED_USERCOPY_PAGESPAN` and `USER_NS`, which is not worth the bootloop
risk. The *sysctl* surface ships wide open, so that is what this fixes —
notably `kernel.perf_event_paranoid`, which defaults to **-1** (unrestricted
perf access for unprivileged processes, a well-known local-exploit primitive).

### Do not harden eBPF here

`kernel.unprivileged_bpf_disabled=1` and `net.core.bpf_jit_harden=2` both
**break the boot on this device.** netd loads eBPF programs via
`/apex/com.android.tethering/lib64/libnetd_updatable.so` for network accounting
and firewalling, over the unprivileged `bpf()` path. Restrict it and
`libnetd_updatable_init` aborts, netd crash-loops, and the device never
finishes booting — deceptively, adb still works and `system_server` is running,
but the `settings` service never registers.

Recovery:

```sh
adb shell su -c 'touch /data/adb/modules/hardening/disable' && adb reboot
```

### perf_event_paranoid needs a late pass

Android's init writes `kernel.perf_event_paranoid=-1` itself, *after*
`post-fs-data` runs, for Perfetto and simpleperf. Setting it early silently
does nothing, so `service.sh` re-runs the whole sysctl script at `late_start`.
`set_sysctl` skips values already at target, so re-running is free.

### 2G

Not handled here, though it is worth turning off — 2G has no mutual
authentication and weak or absent encryption, which is what IMSI catchers
exploit. It simply cannot be driven from a shell on this build:

- `cmd phone set-allowed-network-types-for-users` rejects every argument form
  (numeric bitmask, pipe-separated names, with and without `-s`) with
  `No valid NETWORK_TYPES_BITMASK`.
- `settings put global preferred_network_mode 25` writes successfully but
  telephony ignores it; `get-allowed-network-types` still reports `GPRS|EDGE|GSM`.

`carrier_config` reports `hide_enable_2g_bool=false` for the active SIM, so the
toggle exists in the UI: **Settings → Network & internet → SIMs → Allow 2G**.

### Auto-reboot to BFU

Defaults to 18 hours locked, matching GrapheneOS. Returning to
Before-First-Unlock evicts disk encryption keys from RAM and reseals `/data` —
the strongest anti-forensic control available without GrapheneOS itself. Radios
switch off after 15 minutes idle. Both are `hardening.nix` arguments
(`rebootIdleHours`, `radioIdleMinutes`); set either to `0` to disable.

## stealth

Spoofs the properties that root detectors, banking apps and Play Integrity read
to determine whether the bootloader is unlocked and the build is modified.

`post-fs-data.sh` runs **before zygote** (before any app starts) and uses
`resetprop` to overwrite read-only properties in memory:

| Property                          | Stock value | Spoofed value  |
| --------------------------------- | ----------- | -------------- |
| `ro.boot.verifiedbootstate`       | `orange`    | `green`        |
| `ro.boot.flash.locked`            | `0`         | `1`            |
| `ro.boot.vbmeta.device_state`     | `unlocked`  | `locked`       |
| `ro.secureboot.lockstate`         | `unlocked`  | `locked`       |
| `ro.debuggable`                   | `1`         | `0`            |
| `ro.build.type`                   | `userdebug` | `user`         |
| `ro.build.tags`                   | `test-keys` | `release-keys` |

`service.sh` re-applies the same props at `late_start` (Android init overwrites
some during boot) and forces SELinux to enforcing.

### resetprop

The module needs a `resetprop` binary to modify `ro.*` properties. It probes
`/data/adb/ksu/bin/resetprop`, `/data/adb/magisk/resetprop`, and the module
directory itself. If none is found it falls back to `setprop`, which cannot
write read-only properties.

Check whether resetprop is already present:

```sh
adb shell su -c 'ls /data/adb/ksu/bin/resetprop /data/adb/magisk/resetprop 2>/dev/null'
```

If not, extract it from a Magisk release (the binary works standalone, no full
Magisk install needed):

```sh
curl -Lo Magisk.apk https://github.com/topjohnwu/Magisk/releases/latest/download/Magisk-v28.1.apk
unzip -j Magisk.apk lib/arm64-v8a/libmagisk64.so
adb push libmagisk64.so /data/local/tmp/resetprop
adb shell su -c 'mv /data/local/tmp/resetprop /data/adb/ksu/bin/resetprop; chmod 755 /data/adb/ksu/bin/resetprop'
```

### What stealth does NOT cover

This module handles the **property layer** only. Three other layers need
separate tools (all installable as KSU modules, no kernel rebuild):

| Layer | Tool | What it does |
| ----- | ---- | ------------ |
| Device fingerprint | **Play Integrity Fix** (PIF) | Spoofs `ro.build.fingerprint` to a known-good device so DEVICE-level Play Integrity passes. Community-maintained; update the fingerprint JSON when Google rotates. Install: `ksud module install PlayIntegrityFix-*.zip`. |
| Per-app root hiding | **Shamiko** (+ ZygiskNext) | Unmounts KSU/module overlays and hides su in the mount namespace of deny-listed apps. Needed for banking apps that scan `/proc/self/mountinfo` for `/nix`, `/data/adb`, or overlay mounts. Install ZygiskNext first, then Shamiko. |
| Hardware attestation | **Tricky Store** | Spoofs the TEE keybox so STRONG-level Play Integrity (hardware attestation) passes. Needs a valid leaked keybox; without one only DEVICE level is reachable. |

### Frida stealth

The module installs `frida-start` and `frida-stop` scripts to `/system/bin/`.
They wrap a user-provided frida-server binary with stealth:

- **Renamed binary** — copied to `/data/local/tmp/.cache/<random-uuid>` so
  the process name in `/proc` never contains "frida"
- **Non-standard port** — defaults to `29170` instead of `27042` (the
  first thing detection SDKs scan)
- **Localhost only** — `127.0.0.1`, nothing on the network

Setup once:

```sh
# Use strongR-frida-android for maximum stealth (obfuscated thread names
# and agent strings): github.com/hluwa/strongR-frida-android/releases
adb push frida-server /data/local/tmp/
adb shell su -c 'mkdir -p /data/adb/frida && mv /data/local/tmp/frida-server /data/adb/frida/ && chmod 755 /data/adb/frida/frida-server'
```

Use:

```sh
adb shell su -c 'frida-start'           # or: frida-start 31337
adb forward tcp:29170 tcp:29170
frida -H 127.0.0.1:29170 -f com.shopee.id
```

Stop:

```sh
adb shell su -c 'frida-stop'
```

Stock Frida leaks detection signals that e-commerce apps (Shopee, Tokopedia,
etc.) actively scan for. The main vectors and what covers each one:

| Detection vector | What finds it | What hides it |
| --- | --- | --- |
| Port 27042 open | `connect()` scan | `frida-start` (non-standard port) |
| Process name contains "frida" | `/proc` enumeration | `frida-start` (renamed binary) |
| `/proc/self/maps` contains "frida" | `fopen("/proc/self/maps")` | Kernel maps filter (`build.sh` STEALTH=1) |
| Frida agent strings in memory | `memcmp` on loaded `.so` | **strongR-frida-android** (obfuscated build) |
| Thread names: `gmain`, `gum-js-loop` | `/proc/self/task/*/comm` | **strongR-frida-android** |
| D-Bus protocol on listening port | `recv()` + header check | Hard to avoid — use Frida gadget mode instead |

### Kernel-side stealth

The kernel `build.sh` defaults to `STEALTH=1`, which keeps InfiniR's original
version strings so `uname -r` and `/proc/version` match stock crDroid.
`custom.config` disables `CONFIG_IKCONFIG_PROC`, removing `/proc/config.gz`
entirely so apps cannot read kernel config. The kernel also patches
`fs/proc/task_mmu.c` to filter Frida's injected libraries from
`/proc/PID/maps` and `/proc/PID/smaps` — see `kernel/README.md`.

## adblock

A single `/system/etc/hosts` file mapping ~81k ad and tracker domains to
`127.0.0.1`, Magisk-mounted over the base OS file (which is left untouched).

Hosts-based rather than a browser extension or a blocking resolver for two
reasons:

- It blocks for **every app**, not just the browser — in-app ad SDKs,
  `app-measurement.com`, analytics endpoints, the lot.
- It **survives DNS-over-TLS.** bionic consults the hosts file before it does
  any DNS, so blocking still works with `private_dns_mode=strict` pointed at
  Cloudflare. Verified: `doubleclick.net` resolves to `127.0.0.1` while DoT is
  active. Encrypted DNS and blocking coexist; they do not fight.

Two things it cannot do:

- **Tor Browser bypasses it** — it resolves through Tor, not the system. Tor
  Browser has its own tracker blocking, so this is fine.
- It blocks whole **domains, not paths**, so no cosmetic filtering (blank ad
  slots). A browser-level blocker complements it if that matters.

The list is StevenBlack's unified hosts, pinned in `adblock.nix` by commit
`rev` + `hash` so the build is reproducible. To update: bump `rev`, run the
build once to get the new `hash` from the mismatch error, paste it back.

## nixenter

Native Nix lives at `/nix`, but a terminal app cannot reach it. Termux runs as
an unprivileged app (`untrusted_app` SELinux domain, UID ~10169) and gets
`Permission denied` even listing `/nix` — the store is root-owned and labelled
`system_data_root_file`, which that domain has no policy to traverse or exec.
Verified on-device.

Rather than weaken the store's permissions, `nix-enter` bridges through Magisk
`su` — the same path everything else here uses. In any terminal:

```sh
nix-enter              # root shell with /nix/etc/profile.sh sourced
nix-enter nix --version
ne build .#something   # ne is the short alias
```

The launchers ship as real module files under `system/bin/`, so Magisk
magic-mounts them onto PATH; there is no runtime symlinking to go stale. Note
Magisk finishes mounting `/system/bin` a moment after boot — immediately at
`post-fs-data` the launchers are not yet visible, which is expected.

The first `nix-enter` pops a Magisk superuser prompt; grant it once.

### Auto-enter in the GUI terminal app

The module also overlays `/system/etc/mkshrc` so a GUI terminal app (the AOSP
Terminal) drops **straight into the Nix root shell** on open — no typing. The
appended guard is:

```sh
if (( USER_ID >= 10000 )) && [[ -x /system/bin/nix-enter ]]; then
	exec /system/bin/nix-enter
fi
```

Two things make this safe and correct:

- **`USER_ID >= 10000`** — Android app uids are always ≥ 10000, while adb shell
  is 2000, system is 1000, and root is 0. So this fires *only* in a terminal
  app and can never hijack adb, su, or system shells. mksh sources this file
  only for interactive shells, so non-interactive `sh -c` (scripts, the deploy)
  is untouched too. Verified: an interactive adb shell reports `USER_ID=2000`
  and is left alone.
- **Do not test for `/nix` in the guard.** An app is denied even statting
  `/nix` (`untrusted_app` has no policy for the store), so `[[ -e /nix/... ]]`
  is always false in the terminal and silently stops auto-enter from ever
  firing — a real bug hit during setup. `nix-enter` runs `su` first; root can
  see `/nix`, so the store check belongs there, not here.

No loop: `nix-enter` re-execs through `su`, and that root shell re-sources
mkshrc with `USER_ID=0`, failing the guard.

## sshd — the "real terminal"

An on-device terminal app cannot reach Nix (see `nixenter` above): the
`untrusted_app` sandbox is denied `/nix`. The better answer is your computer's
own terminal over SSH. This module runs **OpenSSH from the nix store** (real,
current OpenSSH, not a sandboxed Android build), bound to `127.0.0.1:8022`,
key-only, forced into the Nix root shell.

Use it:

```sh
adb forward tcp:8022 tcp:8022
ssh poco-f3            # alias in modules/home/ssh; or: ssh -p 8022 root@127.0.0.1
```

You land in a root shell with `/nix/etc/profile.sh` sourced — `nix`, `nix build`,
the lot — in iTerm/tmux/whatever you actually use.

Bound to localhost only and reached via `adb forward`, so **nothing is ever
exposed on the network** — no open port on Wi-Fi, consistent with the privacy
posture. The client keypair lives in `~/.ssh/poco-f3_ed25519`; the authorised
public key is baked into the module (`authorizedKey` arg in `sshd.nix`).

### glibc OpenSSH on Android needs scaffolding

`post-fs-data.sh` creates three things Android lacks but glibc sshd requires:

- **`/etc/passwd` + `/etc/group`** — without them `getpwuid(0)` fails and sshd
  cannot resolve root or its privsep user (`No user exists for uid 0`).
- **`/var/empty`** — OpenSSH's privilege-separation directory is compiled into
  the binary as `/var/empty`; it ignores the passwd home field, so the literal
  path must exist. All three are written via the same rw-remount trick the other
  modules use (works only because dm-verity is off).

`service.sh` runs at late_start, in init's persistent context — a daemon
backgrounded from a transient `su` session gets reaped, so this cannot be done
from an adb one-liner. The `ForceCommand` login honours `$SSH_ORIGINAL_COMMAND`
(so `ssh poco-f3 'nix build ...'` works) and otherwise gives an interactive
shell; a bare `exec sh -l` would swallow sent commands and hang `-tt` sessions.

## Setting defaults

The module makes the tones available; it cannot select them. On Android 16 the
`ringtone`, `notification_sound` and `alarm_alert` keys reject writes from
`settings put` — they are silently ignored, though writes to arbitrary keys
succeed. Pick them in **Settings → Sound & vibration**; iOS entries are
prefixed `iOS_`.

After installing, tones need a media rescan before they appear. That happens on
boot, so the reboot `poco-f3-deploy` performs is sufficient.
