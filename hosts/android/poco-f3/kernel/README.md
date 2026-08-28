# poco-f3 custom kernel

A custom `alioth` kernel: LineageOS 4.19.325 + **KernelSU-Next** (kernel-level
root) + **`CONFIG_USER_NS`** (containers and a real native-Nix build sandbox).
`build.sh` reproduces it; `custom.config` is the fragment merged onto the
running-kernel config.

## Why it exists

The stock LineageOS kernel ships `# CONFIG_USER_NS is not set`, which forced two
compromises documented elsewhere in this host:

- Nix ran with `sandbox = false` — no build isolation.
- Root was Magisk (userspace) rather than kernel-level.

This kernel fixes both. Verified on the booted phone:

- `unshare -Ur id` → `uid=0(root)` (rootless user namespace with root mapping —
  returns *Operation not permitted* on the stock kernel).
- A from-source `nix build` runs inside a sandbox; the build's own
  `/proc/self/uid_map` reads `0 0 4294967295`. `sandbox = true` now, dropped
  the `sandbox = false` workaround.
- KernelSU manager reports **Working \<LTS\>**, version 12430, matching the
  kernel; root context is `u:r:su:s0`.

## What changed in the config

`custom.config` (merged over the target's `/proc/config.gz`):

- **Containers/namespaces**: `USER_NS`, `PID_NS`, `IPC_NS`, `POSIX_MQUEUE`
  (the rest — `NET_NS`, `UTS_NS`, `BRIDGE`, `VETH`, `OVERLAY_FS`, `MEMCG`,
  `BPF_SYSCALL`, `SECCOMP` — were already on).
- **Container runtime net**: `BRIDGE_NETFILTER`, `NF_NAT`, `IP_NF_NAT`,
  `MASQUERADE`, conntrack, `CGROUP_PIDS`/`_DEVICE`, `BLK_CGROUP`,
  `CFS_BANDWIDTH`.
- **KernelSU**: `KSU=y` plus its dependency `KPROBES=y` (the kprobe hook path).
- **Perf**: `TCP_CONG_BBR` + `NET_SCH_FQ`, with `DEFAULT_TCP_CONG="bbr"`. BBR
  needs `TCP_CONG_ADVANCED=y` to be selectable at all — without it olddefconfig
  silently drops BBR and leaves `cubic`. Verified live:
  `/proc/sys/net/ipv4/tcp_congestion_control` reads `bbr`.

`CONFIG_MODULE_SIG` is already unset upstream, so no signing conflict.

## Build notes / landmines hit

- **Build host**: the Mac is `aarch64-darwin` and cannot build a Linux kernel.
  It builds inside the Colima aarch64 Linux VM (Docker), which is native arm64 —
  no cross toolchain. The community Proton Clang is x86_64 and won't run there;
  the container's native aarch64 `clang-14` + `LLVM=1` compiles the 4.19 tree
  fine.
- **KernelSU version**: the `next`/v3.x branch fails to compile on 4.19 — it
  uses 5.10+ APIs (`iopoll`, `remap_file_range`, `handle_inode_event`,
  `SECCOMP_ARCH_NATIVE_NR`, `uapi/linux/mount.h`). **v1.0.5** is the newest tag
  whose driver builds on 4.19.
- **`path_umount` link error**: KSU injects a `path_umount` implementation into
  `fs/namespace.c` at Makefile-parse time (5.9+ symbol absent on 4.19). If
  `fs/namespace.o` was already cached from an earlier run it won't contain the
  symbol and the final link fails with `undefined symbol: path_umount`. Force a
  rebuild of that one object (`rm out/fs/namespace.o; touch fs/namespace.c`).
- **boot.img format**: the LineageOS boot.img holds a **bare uncompressed
  `Image`** (~53 MB); the dtb lives in `dtbo`/`vendor_boot`. Swap in our
  uncompressed `Image`, not `Image.gz-dtb` — using the gzip one risks a
  non-boot. Repack with `magiskboot repack` so the header and the clean
  LineageOS ramdisk are preserved (no Magisk — root is in the kernel now).

## Flashing and recovery

```sh
fastboot flash boot out/custom_boot.img
```

Recovery from a bad flash is always: `fastboot flash boot <pristine boot.img>`
(the unmodified LineageOS kernel). The device is A/B; this writes the current
slot only.

## First boot after flashing

KernelSU's `ksud` only deploys once the manager app runs (needs credential
storage, i.e. one PIN unlock), so **modules don't mount on the very first boot**.
Unlock, open **KernelSU Next**, then **reboot once** — after that KernelSU mounts
all `/data/adb/modules` at early boot exactly like Magisk did. The six modules
migrated with zero changes (KernelSU is Magisk-module compatible).

Interactive `su` needs a per-app grant in the manager's **Superuser** tab
(`Superusers: 0` by default). Module scripts run as root automatically and need
no grant; only apps calling `su` themselves (the terminal for `nix-enter`) do.
