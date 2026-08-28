#!/system/bin/sh
# Enter a root shell with the native Nix environment loaded.
#
# Termux runs as an unprivileged app (untrusted_app SELinux domain, UID ~10169)
# and cannot even traverse /nix: the store is root-owned and labelled
# system_data_root_file, which that domain has no policy to read or exec. So a
# terminal reaches Nix the same way everything else on this device does — via
# Magisk su — rather than by loosening permissions on the store.
#
# Magisk magic-mounts this onto /system/bin/nix-enter, so `nix-enter` (or the
# `ne` alias) is on PATH in Termux and any other shell. Run it with no args for
# an interactive root shell, or `nix-enter <cmd...>` to run one command.

if [ "$(id -u)" != "0" ]; then
  # Re-invoke through su. The first run pops a Magisk grant prompt for Termux.
  exec su -c "sh /system/bin/nix-enter $*"
fi

. /nix/etc/profile.sh

if [ "$#" -gt 0 ]; then
  exec "$@"
else
  cd "$HOME" 2>/dev/null || cd /data/local/nixhome
  exec "${SHELL:-/system/bin/sh}" -l
fi
