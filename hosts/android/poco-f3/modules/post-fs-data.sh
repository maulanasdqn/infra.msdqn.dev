#!/system/bin/sh
# Two Android facts make a native /nix impossible without help:
#
#   1. / is read-only ext4, so the mountpoint cannot simply be created.
#      Remounting it rw works only because LineageOS disables dm-verity;
#      this would fail on stock MIUI.
#   2. There is no /etc/resolv.conf. Android resolves DNS through bionic and
#      netd, so glibc binaries fail every hostname lookup while toybox ping
#      succeeds — which makes it look like the network is fine when Nix
#      cannot resolve anything at all.

STORE=@store@

mkdir -p "$STORE"
chmod 0755 "$STORE"

need_rw=0
[ -d /nix ] || need_rw=1
[ -f /system/etc/resolv.conf ] || need_rw=1

if [ "$need_rw" = "1" ]; then
  mount -o remount,rw / || exit 0

  if [ ! -d /nix ]; then
    mkdir -p /nix
    chmod 0755 /nix
  fi

  if [ ! -f /system/etc/resolv.conf ]; then
    printf '@resolv@' > /system/etc/resolv.conf
    chmod 0644 /system/etc/resolv.conf
  fi

  mount -o remount,ro /
fi

mountpoint -q /nix || mount --bind "$STORE" /nix

# Android has no /dev/shm (it uses ashmem), so POSIX shared memory is absent.
# Python multiprocessing needs it for semaphores, and the Nix sandbox inherits
# the lack — any such build (e.g. nixos-render-docs, which nixvim/home-manager
# use for manpages) dies with "FileNotFoundError" in SemLock. Provide it.
if [ ! -d /dev/shm ]; then
  mkdir -p /dev/shm
  mount -t tmpfs -o size=256M,mode=1777 tmpfs /dev/shm
fi

# Seed a working nix.conf on a fresh store if one is not already present.
#   sandbox=true         - the custom kernel enables CONFIG_USER_NS, so Nix gets
#                          a real build sandbox (rootless user namespaces). On the
#                          stock LineageOS kernel this had to be false.
#   nix-path             - lets legacy `nix-shell -p` / <nixpkgs> resolve via the
#                          flake registry; without it the flakes-only setup gives
#                          "file 'nixpkgs' was not found in the Nix search path"
if [ ! -f /nix/etc/nix.conf ]; then
  mkdir -p /nix/etc
  cat > /nix/etc/nix.conf <<'CONF'
sandbox = true
build-users-group =
experimental-features = nix-command flakes
max-jobs = auto
nix-path = nixpkgs=flake:nixpkgs
CONF
fi
