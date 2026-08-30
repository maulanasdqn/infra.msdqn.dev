# poco-f3 custom kernel — `msdqn-kernel`

A custom `alioth` kernel for **crDroid 16 (Android 16)**: InfiniR (raystef66)
`16.0-alioth` + **KernelSU-Next** + **`CONFIG_USER_NS`/`PID_NS`** + **BBR**,
renamed `msdqn-kernel`. `build.sh` reproduces the `Image`; `custom.config` is the
fragment merged onto InfiniR's `vendor/alioth_defconfig`.

`uname -r` → `4.19.404-msdqn-kernel`.

## Why it exists

crDroid ships the stock InfiniR kernel with `# CONFIG_USER_NS is not set`, which
forced two compromises: Nix ran `sandbox = false`, and — worse — any local
from-source build hung in uninterruptible **D-state** (survives `SIGKILL`, only a
reboot clears it). This kernel enables `USER_NS`/`PID_NS`, so Nix gets a real
rootless build sandbox and the D-state hang is gone.

Verified on the booted phone, from a root shell (`u:r:su:s0`):

```
unshare -U -r --map-root-user id   → uid=0(root)   (/proc/self/uid_map = 0 0 1)
```

From the non-root `shell` domain this still prints `overflowuid` — that is an
SELinux restriction on writing `uid_map`, **not** a kernel limitation; the Nix
daemon runs as root, where it works.

## History — this replaces the LineageOS build

The device was on LineageOS with a hand-built `4.19.325` kernel; it was wiped to
crDroid on 2026-08-28, which runs InfiniR. So the source base changed from
LineageOS `android_kernel_xiaomi_sm8250` to **`raystef66/InfiniR_kernel_alioth`**
(`16.0-alioth`, pinned `020d4f362`). KernelSU is **already vendored** in the
InfiniR tree at `drivers/kernelsu` (tracked, ~32 files) — no `setup.sh` injection,
so the old `path_umount` link landmine does not apply here.

## Build landmines (all handled by `build.sh`)

1. **The Mac mount is case-insensitive.** `net/netfilter` has case-colliding
   files (`xt_DSCP.c` is stored as `xt_dscp.c`; uapi headers `xt_CONNMARK.h` /
   `xt_connmark.h` collide). Building on `/Users` fails with
   `No rule to make target 'net/netfilter/xt_DSCP.o'`. Fix: build on a
   **case-sensitive ext4 loop image** (`/Users/ms/kbuild/ks.ext4` mounted at
   `/mnt/ks` in the VM), and materialise the tree with `git clone` (checkout from
   git objects restores the correct case). The VM root disk is only ~6 GB free, so
   the image is backed by the big `/Users` mount (~479 GB).

2. **InfiniR injects ML-only `-mllvm` flags** (`Makefile` ~lines 706-708:
   `-mllvm -regalloc-enable-advisor=release`, `-mllvm -enable-ml-inliner=release`).
   These need the maintainer's Neutron/AOSP clang, which is built with the ML
   regalloc model compiled in — and is x86_64, so it will not run in the arm64 VM.
   Distro clang (both 14 and 18) dies at `scripts/mod/empty.o` with
   `error: Requested regalloc eviction advisor analysis could not be created`.
   `build.sh` `sed`s those lines out (keeping `-mcpu=cortex-a55` and
   `-hot-cold-split`) and builds with `clang-14` + `LLVM=-14`. The POLLY block is
   guarded by `CONFIG_POLLY_CLANG` (off), so it is inert.

3. **`/proc/config.gz` on InfiniR lies.** InfiniR patches `kernel/Makefile` so the
   embedded IKCONFIG (`config_data.gz`) is generated from a *fixed*
   `arch/arm64/configs/stock_defconfig`, **not** the live `.config`. So on the
   stock kernel `/proc/config.gz` always shows `# CONFIG_USER_NS is not set` and
   `cubic` regardless of what was actually compiled — it is useless for verifying
   USER_NS, and it fooled an earlier attempt into thinking a kernel named `_ns_`
   had USER_NS when it did not. Ground truth is the compiled binary:
   `out/kernel/user_namespace.o` exists (only built when `USER_NS=y`) and
   `llvm-nm out/vmlinux | grep create_user_ns` is present. `build.sh` also points
   the IKCONFIG rule back at `$(KCONFIG_CONFIG)` so `/proc/config.gz` becomes
   honest (`USER_NS=y`, `bbr`).

4. **`CONFIG_TCP_CONG_ADVANCED=y` is required** or `olddefconfig` silently drops
   `TCP_CONG_BBR` and leaves `cubic`. Verified live:
   `/proc/sys/net/ipv4/tcp_congestion_control` reads `bbr`.

## Repack and flash

The crDroid `boot.img` is `HEADER_VER 3`, `KERNEL_FMT raw` (a bare uncompressed
`Image`; the dtb lives in a separate partition), so only the kernel is swapped.
`magiskboot` is on the device at `/data/adb/ksu/bin/magiskboot`.

```sh
adb push /Users/ms/kbuild/Image_msdqn_kernel /data/local/tmp/Image
adb shell su -c '
  cd /data/local/tmp
  dd if=/dev/block/by-name/boot_a of=work.img
  /data/adb/ksu/bin/magiskboot unpack work.img
  cp /data/local/tmp/Image kernel
  /data/adb/ksu/bin/magiskboot repack work.img new-boot.img'
adb pull /data/local/tmp/new-boot.img
adb reboot bootloader
fastboot flash boot_a new-boot.img
fastboot reboot
```

Boots in ~40 s; flashing `boot` does **not** touch `/data`. Recovery from a bad
flash (A/B, current slot only):

```sh
fastboot flash boot_a /Users/ms/kbuild/stock_boot_infinir_crdroid_backup.img
```

Keep a pristine boot backup **on the Mac** — a custom `boot` on both A/B slots
once bootlooped and could only be recovered by a full fastboot ROM re-flash.

## Sandbox

With this kernel the `nixbind` module seeds `nix.conf` with `sandbox = true`
(`../modules/post-fs-data.sh`). `nix.conf` lives on the persistent store
(`/data/nix/etc`), so once set it survives reboots. Confirm:
`nix config show | grep '^sandbox '` → `sandbox = true`.

## Artifacts

- `/Users/ms/kbuild/Image_msdqn_kernel` — the compiled kernel.
- `/Users/ms/kbuild/custom_boot_msdqn_kernel.img` — flashable crDroid boot.
- `/Users/ms/kbuild/stock_boot_infinir_crdroid_backup.img` — pre-USER_NS InfiniR
  boot, the un-brick fallback.
