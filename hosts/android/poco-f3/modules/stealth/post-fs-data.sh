#!/system/bin/sh
MODDIR="${0%/*}"

RPROP=""
for p in \
  /data/adb/ksu/bin/resetprop \
  /data/adb/magisk/resetprop \
  /data/adb/ap/bin/resetprop \
  "${MODDIR}/resetprop"; do
  [ -x "$p" ] && { RPROP="$p"; break; }
done

if [ -z "$RPROP" ]; then
  echo "[stealth] resetprop not found — ro.* props cannot be spoofed" > /dev/kmsg 2>/dev/null
fi

rp() {
  if [ -n "$RPROP" ]; then
    "$RPROP" "$1" "$2" 2>/dev/null
  else
    setprop "$1" "$2" 2>/dev/null
  fi
}

rpd() {
  [ -n "$RPROP" ] && "$RPROP" --delete "$1" 2>/dev/null
}

rp ro.boot.verifiedbootstate green
rp ro.boot.flash.locked 1
rp ro.boot.vbmeta.device_state locked
rp ro.secureboot.lockstate locked
rp ro.boot.warranty_bit 0
rp ro.warranty_bit 0

rp ro.debuggable 0
rp ro.secure 1
rp ro.build.type user
rp ro.build.tags release-keys
rp ro.vendor.build.type user
rp ro.system.build.type user
rp ro.system_ext.build.type user
rp ro.product.build.type user
rp ro.odm.build.type user

rpd ro.build.selinux
