#!/usr/bin/env bash
# Reproduce the alioth custom kernel: LineageOS 4.19.325 + KernelSU-Next +
# CONFIG_USER_NS (containers / native Nix sandbox).
#
# The Mac is aarch64-darwin and cannot build a Linux kernel, so this runs inside
# the Colima aarch64 Linux VM via Docker — native arm64 compilation, no cross
# toolchain. Run it from the repo root with Colima running.
#
#   DOCKER_HOST=unix://$HOME/.colima/default/docker.sock \
#     bash hosts/android/poco-f3/kernel/build.sh
#
# Output: hosts/android/poco-f3/kernel/out/custom_boot.img  (fastboot flash boot)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KREV=71b13e62f057a649b77fe4062feb73ee72ad609c   # LineageOS lineage-23.2 pin
KSU_TAG=v1.0.5                                   # newest KSU-Next that builds on 4.19
IMG="$HERE/out"
mkdir -p "$IMG"

# A pristine LineageOS boot.img is needed as the repack template + recovery.
STOCK_BOOT="${STOCK_BOOT:-$HERE/stock_boot.img}"
[ -f "$STOCK_BOOT" ] || {
  echo "Need a pristine LineageOS boot.img at $STOCK_BOOT (from the matching build)." >&2
  echo "Download the device's boot.img and set STOCK_BOOT=/path/to/boot.img" >&2
  exit 1
}

docker rm -f kbuild >/dev/null 2>&1 || true
docker run -d --name kbuild -w /work ubuntu:22.04 sleep infinity >/dev/null

docker exec kbuild bash -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq git make bc bison flex libssl-dev libncurses-dev \
    build-essential ca-certificates curl python3 zip cpio kmod libelf-dev \
    lld llvm clang
'

docker cp "$HERE/custom.config" kbuild:/work/custom.config
docker cp "$STOCK_BOOT" kbuild:/work/stock_boot.img

docker exec kbuild bash -c "
  set -e
  cd /work
  git clone --depth 30 -b lineage-23.2 \
    https://github.com/LineageOS/android_kernel_xiaomi_sm8250.git kernel
  cd kernel
  git fetch --depth 1 origin $KREV && git checkout $KREV

  # KernelSU-Next: v1.0.5 is the newest tag whose driver compiles on 4.19.
  # (next/v3.x use 5.10+ APIs: iopoll, remap_file_range, path_umount, etc.)
  curl -LSs https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/$KSU_TAG/kernel/setup.sh \
    | bash -s $KSU_TAG

  # Start from the exact running-kernel config, then merge our fragment. Using
  # the real config (not a reconstructed defconfig) guarantees parity.
  mkdir -p out
  # base.config must be the target's /proc/config.gz, provided out of band:
  [ -f /work/base.config ] || zcat /proc/config.gz 2>/dev/null > /work/base.config || true
  ARCH=arm64 scripts/kconfig/merge_config.sh -O out /work/base.config /work/custom.config

  # KSU injects path_umount into fs/namespace.c at Makefile-parse time; force a
  # rebuild of that object so the symbol is present at link.
  rm -f out/fs/namespace.o; touch fs/namespace.c

  make -j\"\$(nproc)\" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
    KBUILD_BUILD_USER=ms KBUILD_BUILD_HOST=poco-f3 Image.gz-dtb

  # The LineageOS boot.img carries a bare uncompressed Image (dtb is in dtbo /
  # vendor_boot), so swap in our uncompressed Image, not Image.gz-dtb.
  curl -LSs -o /work/magiskboot https://raw.githubusercontent.com/…/magiskboot 2>/dev/null || true
"

echo
echo "Kernel built. Repack with magiskboot (extract from the Magisk apk):"
echo "  magiskboot unpack stock_boot.img"
echo "  cp out/arch/arm64/boot/Image kernel && magiskboot repack stock_boot.img custom_boot.img"
echo "Then: fastboot flash boot custom_boot.img   (recovery: flash the stock boot.img back)"
