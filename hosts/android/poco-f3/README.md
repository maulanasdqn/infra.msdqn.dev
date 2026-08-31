# poco-f3 — POCO F3 / M2012K11AG (`alioth`)

crDroid 16 (Android 16) on the custom **`msdqn-kernel`** with KernelSU-Next.
**Not a nix-on-droid host.**

Root is **KernelSU-Next** (kernel-level), not Magisk — see `kernel/README.md`.
The custom `msdqn-kernel` enables `CONFIG_USER_NS`, so Nix runs with a real build
sandbox (`sandbox = true`) and rootless containers work. The `/data/adb/modules`
are Magisk-format, so they load unchanged under KernelSU-Next (which is baked
into the InfiniR base crDroid ships).

## Why this is a home-manager config, not nix-on-droid

nix-on-droid runs the store under **proot**, which is exactly what `honor` has
to do because its bootloader is permanently locked. This phone is unlocked and
rooted, so `/nix` is a real bind mount and Nix runs **natively** — no proot, no
syscall emulation.

That means this host deliberately does **not** import `../default.nix`. That
file sets nix-on-droid-only options (`environment.packages`, `terminal.font`,
`system.stateVersion`) which do not exist in a standalone home-manager
evaluation. It is a plain `homeManagerConfiguration` for `aarch64-linux`
instead.

It also means this host does **not** need the 25.11 pinning described in
`../honor/README.md`. The glibc 2.42 regression that freezes neovim 0.12 and
breaks builds is a *proot* bug, so with proot gone this host tracks the same
unstable `nixpkgs`/`nixvim`/`home-manager` as the desktops.

## Applying

Two halves, both driven by Nix.

**System side** — the Magisk modules that make `/nix` exist and swap the system
sounds. Built and deployed from the Mac, see `modules/README.md`:

```sh
nix run .#poco-f3-deploy    # build + push + install + reboot
```

**User side** — shell, prompt, editor and CLI tooling (zsh + starship + neovim +
the same `cli.nix` tools as the darwin hosts):

```sh
nix run .#poco-f3-hm-deploy    # build on Colima, import + activate on the phone
```

**Do not run `home-manager switch` on the phone.** The device has 5.5 GB RAM and
`nix-env -i home-manager-path` (the buildEnv that unions ~1108 packages) hangs
indefinitely on-device. `hm-deploy.sh` therefore builds the `activationPackage` on
the Colima aarch64-linux VM, copies the closure over, and activates by pointing the
profile straight at the pre-built `home-manager-path` with `nix-env --set` (zero
build) and hand-linking the generation's dotfiles. Re-run it to update the config.

Two config gotchas baked into `default.nix`:

- **`manual.manpages.enable = false` + `news.display = "silent"`** — the
  home-manager reference manpage derivation fails on this target.
- **`/dev/shm` is required.** Android has none (it uses ashmem), so Python
  multiprocessing — which `nixos-render-docs` uses for manpages — dies with
  `FileNotFoundError` in `SemLock`. The `nixbind` module mounts a tmpfs at
  `/dev/shm` at boot.

`hm-deploy.sh` also wires **Termux** to drop straight into the native nix zsh:
opening Termux `exec su -c '… zsh -l'` after a one-time KernelSU Superuser grant for
`com.termux` (SELinux blocks non-root domains from `/nix`, so it must go through
`su`). And it seeds `/data/local/nixhome/etc/{passwd,group}` which `nixbind`
bind-mounts over `/etc` so glibc `getpwuid(0)` resolves root (zsh needs it).

## How /nix exists at all

Two Android facts have to be worked around, both handled by the `nixbind`
Magisk module (`post-fs-data.sh`), not by Nix:

1. `/` is **read-only ext4**, so the `/nix` mountpoint cannot simply be
   created. The module briefly remounts `/` read-write to `mkdir /nix`, then
   binds `/data/nix` over it and remounts read-only. This works only because
   crDroid ships with **dm-verity disabled**; it would fail on stock MIUI.
2. Android has **no `/etc/resolv.conf`** — DNS goes through bionic and netd.
   glibc binaries therefore fail every hostname lookup while toybox `ping`
   succeeds, which makes it look like the network is fine when Nix cannot
   resolve anything. The module writes a resolver pointing at `1.1.1.1`.

The store lives on `/data/nix` (f2fs, ~104 GB free) and is bind-mounted to
`/nix` on every boot. `/` being read-only also means the mountpoint does not
survive an OTA, hence recreating it each boot rather than once.

## sandbox = true (custom kernel)

`/nix/etc/nix.conf` sets `sandbox = true`. The custom `msdqn-kernel` (`kernel/`)
enables `CONFIG_USER_NS`/`CONFIG_PID_NS`, so Nix gets a real rootless build
sandbox. Verified from root: `unshare -U -r --map-root-user id` → `uid=0(root)`
(`/proc/self/uid_map` = `0 0 1`).

Historical note: on the **stock** InfiniR/crDroid kernel these were unset, so
this had to be `sandbox = false` and — worse — local from-source builds hung in
uninterruptible D-state. The custom kernel removed that tradeoff — see
`kernel/README.md`.

## HOME

`home.homeDirectory` is `/data/local/nixhome` rather than `/data/local/tmp/...`
so it is not treated as scratch space. Note that `su` sets `HOME=/`, so any
shell glue must set `HOME` **unconditionally** — a `${HOME:-default}` fallback
silently leaves it as `/` and Nix then tries to create `/.cache` on a read-only
filesystem.

## Firmware

crDroid 16 for `alioth` needs a recent **HyperOS** (`…TKHMIXM`) firmware base as
its vendor firmware — not MIUI 14; the device currently runs `V816.0.3.0.TKHMIXM`.
Flash the matching fastboot ROM's `flash_all.sh`. Never `flash_all_lock.sh`: it
relocks the bootloader, which bricks a device running a custom ROM.
