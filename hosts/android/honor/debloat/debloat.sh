#!/usr/bin/env bash
#
# MagicOS debloat for the HONOR X9c (BRP-NX1). Uses `pm disable-user` over adb:
# no root, no data loss, fully reversible. Package list lives in packages.txt.
#
# Usage:
#   ./debloat.sh disable   # disable every package in packages.txt
#   ./debloat.sh enable    # re-enable every package in packages.txt
#   ./debloat.sh status    # show current enabled/disabled state
#
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
list="$here/packages.txt"
action="${1:-}"

case "$action" in
  disable|enable|status) ;;
  *) echo "usage: $0 {disable|enable|status}" >&2; exit 2 ;;
esac

command -v adb >/dev/null || { echo "adb not found in PATH" >&2; exit 1; }
adb get-state >/dev/null 2>&1 || { echo "no device connected (check 'adb devices')" >&2; exit 1; }

# Strip inline comments + blanks from the package list.
packages="$(sed 's/#.*//' "$list" | tr -d '[:blank:]' | grep -v '^$' || true)"

printf '%-42s %s\n' "PACKAGE" "RESULT"
while IFS= read -r p; do
  [ -z "$p" ] && continue
  # `adb shell` reads stdin; redirect from /dev/null so it doesn't swallow the
  # while-loop's input and stop after the first package.
  case "$action" in
    disable) r="$(adb shell "pm disable-user --user 0 $p" </dev/null 2>&1 | tr -d '\r')" ;;
    enable)  r="$(adb shell "pm enable $p"                </dev/null 2>&1 | tr -d '\r')" ;;
    status)
      if adb shell "pm list packages -d $p" </dev/null 2>/dev/null | tr -d '\r' | grep -q "package:$p$"; then
        printf '%-42s %s\n' "$p" "disabled"
      elif adb shell "pm list packages -e $p" </dev/null 2>/dev/null | tr -d '\r' | grep -q "package:$p$"; then
        printf '%-42s %s\n' "$p" "enabled"
      else
        printf '%-42s %s\n' "$p" "absent"
      fi
      continue ;;
  esac
  printf '%-42s %s\n' "$p" "$r"
done <<< "$packages"
