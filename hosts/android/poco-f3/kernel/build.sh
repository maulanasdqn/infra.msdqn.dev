#!/usr/bin/env bash
# Reproduce the alioth "msdqn-kernel": InfiniR (raystef66) 16.0-alioth +
# KernelSU-Next + CONFIG_USER_NS/PID_NS + BBR, for crDroid 16 (Android 16).
#
# The Mac is aarch64-darwin and cannot build a Linux kernel, so this drives the
# Colima aarch64 Linux VM (native arm64, no cross toolchain). It also cannot
# build ON the /Users mount: that mount is CASE-INSENSITIVE and net/netfilter
# has case-colliding files (xt_DSCP.c vs xt_dscp.c) that make the build fail
# with "No rule to make target xt_DSCP.o". So the kernel tree lives on a
# case-sensitive ext4 loop image, itself backed by the big /Users mount.
#
# Prereqs: Colima running. Run from the repo root:
#   bash hosts/android/poco-f3/kernel/build.sh
#
# Output (inside the VM): /mnt/ks/kernel/out/arch/arm64/boot/Image, copied to
# /Users/ms/kbuild/Image_msdqn_kernel on the Mac. Repack + flash: see README.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KREV=020d4f362                                    # InfiniR 16.0-alioth pin
IMG_EXT4=/Users/ms/kbuild/ks.ext4                 # case-sensitive build fs
MNT=/mnt/ks
KDIR="$MNT/kernel"
OUT=/Users/ms/kbuild/Image_msdqn_kernel

run() { colima ssh -- bash -lc "$1"; }

echo "==> ensure case-sensitive ext4 loop at $MNT (macOS mount is case-insensitive)"
run "
  if ! mountpoint -q $MNT; then
    [ -f $IMG_EXT4 ] || { fallocate -l 30G $IMG_EXT4; sudo mkfs.ext4 -q -F $IMG_EXT4; }
    sudo mkdir -p $MNT
    sudo mount -o loop $IMG_EXT4 $MNT
    sudo chown \$(id -u):\$(id -g) $MNT
  fi
"

echo "==> toolchain: distro clang-14 (clang-18 also works once ML flags are stripped)"
run "which clang-14 >/dev/null 2>&1 || { sudo apt-get update -qq; sudo apt-get install -y -qq clang-14 lld-14 llvm-14; }"

echo "==> clone InfiniR $KREV into the case-sensitive fs"
run "
  set -e
  if [ ! -d $KDIR/.git ]; then
    git clone --no-hardlinks -b 16.0-alioth https://github.com/raystef66/InfiniR_kernel_alioth.git $KDIR
  fi
  cd $KDIR && git fetch --depth 1 origin $KREV && git checkout -q $KREV
"

echo "==> config: InfiniR alioth defconfig + our fragment"
colima ssh -- bash -lc "cat > $KDIR/custom.config" < "$HERE/custom.config"
run "
  set -e
  cd $KDIR
  make O=out ARCH=arm64 LLVM=-14 vendor/alioth_defconfig
  ARCH=arm64 scripts/kconfig/merge_config.sh -O out out/.config custom.config
"

echo "==> patch Makefile: strip InfiniR ML-only -mllvm flags, honest IKCONFIG, msdqn name"
run "
  set -e
  cd $KDIR
  # These need the maintainer's ML-model clang; distro clang errors at empty.o
  # with 'Requested regalloc eviction advisor analysis could not be created'.
  sed -i '/-mllvm -regalloc-enable-advisor=release/d; /-mllvm -enable-ml-inliner=release/d' Makefile
  # InfiniR ships /proc/config.gz from a FIXED stock_defconfig, not the real
  # .config, so config.gz lies about USER_NS. Point IKCONFIG at the live config.
  sed -i 's|^\\(\\\$(obj)/config_data.gz: \\).*FORCE|\\1\\\$(KCONFIG_CONFIG) FORCE|' kernel/Makefile
  # Rename: uname -r => 4.19.404-msdqn-kernel
  sed -i 's|^EXTRAVERSION = .*|EXTRAVERSION = -msdqn-kernel|' Makefile
  sed -i 's|^CONFIG_LOCALVERSION=.*|CONFIG_LOCALVERSION=\"\"|' out/.config
  printf '' > .scmversion
  make O=out ARCH=arm64 LLVM=-14 olddefconfig
"

echo "==> build Image"
run "
  set -e
  cd $KDIR
  make -j\"\$(nproc)\" O=out ARCH=arm64 LLVM=-14 LLVM_IAS=1 \
    KBUILD_BUILD_USER=msdqn KBUILD_BUILD_HOST=poco-f3 Image
"

echo "==> verify USER_NS is genuinely compiled in (config.gz alone is not enough)"
run "
  set -e
  cd $KDIR
  test -f out/kernel/user_namespace.o
  llvm-nm-14 out/vmlinux | grep -q ' create_user_ns\$'
  scripts/extract-ikconfig out/arch/arm64/boot/Image | grep -E '^CONFIG_(USER_NS|PID_NS)=y'
  cat out/include/config/kernel.release
  cp out/arch/arm64/boot/Image $OUT
"

echo
echo "Image built and copied to $OUT"
echo "Repack + flash (needs the device over adb) — see README.md."
