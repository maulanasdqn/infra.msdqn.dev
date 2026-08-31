#!/usr/bin/env bash
# Push every built KernelSU/Magisk-format module to the phone, install it, and
# reboot once (the device runs KernelSU on crDroid; ksud installs the same zips).
#
# Usage:  nix run .#poco-f3-deploy -- <module.zip> [more.zip ...]
#   or:   nix run .#poco-f3-deploy            (builds and deploys everything)
set -euo pipefail

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mFAIL: %s\033[0m\n' "$*" >&2; exit 1; }

zips=("$@")

if [ ${#zips[@]} -eq 0 ]; then
  say "no zips passed; building .#poco-f3-modules"
  out=$(nix build --no-link --print-out-paths --impure .#poco-f3-modules) \
    || die "build failed (iOS sounds need IOS_RUNTIME_ROOT set — see README)"
  mapfile -t zips < <(find "$out" -name '*.zip' | sort)
fi

[ ${#zips[@]} -gt 0 ] || die "nothing to deploy"

say "waiting for device"
adb wait-for-device
adb shell 'echo ok' >/dev/null 2>&1 || die "adb shell unavailable — is USB debugging on and authorised?"

dev=$(adb shell getprop ro.product.device | tr -d '\r')
[ "$dev" = "alioth" ] || die "device reports '$dev', expected 'alioth'. Refusing."
say "confirmed alioth"

adb shell 'su -c "echo root-ok"' >/dev/null 2>&1 || die "no root — KernelSU su denied"

for z in "${zips[@]}"; do
  name=$(basename "$z")
  say "installing $name"
  adb push "$z" "/data/local/tmp/$name" >/dev/null
  adb shell "su -c 'ksud module install /data/local/tmp/$name'"
  adb shell "su -c 'rm -f /data/local/tmp/$name'"
done

say "syncing and rebooting"
adb shell 'su -c sync'
adb reboot

say "waiting for boot"
for _ in $(seq 1 90); do
  if adb shell 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r' | grep -q 1; then
    say "booted"
    adb shell 'su -c "ls /data/adb/modules/"'
    exit 0
  fi
  sleep 5
done

die "device did not finish booting in time"
