#!/system/bin/sh
MODDIR="${0%/*}"

log() { echo "[stealth] $*" > /dev/kmsg 2>/dev/null; }

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 5; done
sleep 10

[ -f "${MODDIR}/post-fs-data.sh" ] && sh "${MODDIR}/post-fs-data.sh"
log "props re-applied at late_start"

setenforce 1 2>/dev/null
log "SELinux enforcing confirmed"

settings put global adb_wifi_enabled 0 2>/dev/null

log "stealth late_start complete"
