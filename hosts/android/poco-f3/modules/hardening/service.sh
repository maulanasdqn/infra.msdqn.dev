#!/system/bin/sh
# Privacy-first defaults + GrapheneOS-inspired behaviours, applied at late_start
# once the framework is up (settings and cmd phone are unavailable earlier).

REBOOT_IDLE_HOURS=@rebootIdleHours@
RADIO_IDLE_MINUTES=@radioIdleMinutes@

log() { echo "[hardening] $*" > /dev/kmsg 2>/dev/null; }

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 5; done
sleep 20

# Re-apply the sysctls now that init has finished. Android's init writes
# kernel.perf_event_paranoid=-1 of its own accord (for Perfetto/simpleperf)
# *after* post-fs-data runs, silently undoing the early pass. Re-running here
# is idempotent — set_sysctl skips anything already at the target value.
[ -f "${0%/*}/post-fs-data.sh" ] && sh "${0%/*}/post-fs-data.sh"
log "sysctls re-applied at late_start"

put() { settings put "$1" "$2" "$3" >/dev/null 2>&1; }

# ---------------------------------------------------------------- privacy ----

# Background scanning keeps reporting nearby APs and beacons to whatever holds
# location, even with Wi-Fi and Bluetooth "off". This is the single biggest
# passive location leak on a stock Android install.
put global wifi_scan_always_enabled 0
put global ble_scan_always_enabled 0
put global network_recommendations_enabled 0

# Randomised MAC per network, so the hardware address does not identify the
# device across APs.
put global wifi_connected_mac_randomization_enabled 1

# No telemetry, no crash upload, no usage stats.
put global device_provisioning_mobile_data_enabled 0
put secure send_action_app_error 0
put global send_action_app_error 0
put system send_action_app_error 0
put global stay_on_while_plugged_in 0

# Captive-portal probes phone home to a fixed endpoint on every network join.
# Point them at a neutral host rather than Google's.
put global captive_portal_mode 1
put global captive_portal_use_https 1
put global captive_portal_http_url "http://detectportal.firefox.com/success.txt"
put global captive_portal_https_url "https://detectportal.firefox.com/success.txt"
put global captive_portal_fallback_url "http://detectportal.firefox.com/success.txt"

# Private DNS: opportunistic, NOT strict.
#
# Strict mode (private_dns_mode=hostname) pins DoT to a named server and does
# *no* fallback. If port 853 to that server is blocked or throttled — common on
# Indonesian ISPs, hotel Wi-Fi, and captive portals — every Android app gets
# "unknown host" and the phone's networking silently dies. That is exactly what
# happened here: strict DoT to one.one.one.one blackholed bionic DNS, which is
# why Orbot could never resolve a relay and Tor "never connected".
#
# Opportunistic still upgrades to DoT whenever the network offers it, but falls
# back to normal DNS instead of blackholing. When Orbot is the active VPN, DNS
# goes through Tor regardless, so the plaintext-fallback exposure is bounded.
put global private_dns_mode opportunistic

# ------------------------------------------------------------ lockscreen ----

# Scrambled PIN pad defeats shoulder-surfing and smudge analysis.
put system lockscreen_scramble_pin_layout 1
put secure lock_screen_show_notifications 1
put secure lock_screen_allow_private_notifications 0
put secure lock_screen_show_qr_code_scanner 0
put global adb_enabled_on_lockscreen 0

# 2G is deliberately NOT handled here. It has no mutual authentication and weak
# or absent encryption, which is exactly what IMSI catchers exploit, so turning
# it off is worth doing — but it cannot be done from a shell on this build:
#
#   cmd phone set-allowed-network-types-for-users  rejects every argument form
#     (numeric bitmask, pipe-separated names, with and without -s), answering
#     "No valid NETWORK_TYPES_BITMASK".
#   settings put global preferred_network_mode 25  writes successfully but
#     telephony ignores it; get-allowed-network-types still reports GPRS|EDGE|GSM.
#
# carrier_config reports hide_enable_2g_bool=false for the active SIM, so the
# toggle does exist in the UI:
#   Settings > Network & internet > SIMs > Allow 2G
# Doing it there persists, which is why this script does not fake it.

# --------------------------------------------------- idle radios + reboot ----

# GrapheneOS reboots after a period locked so the device returns to
# Before-First-Unlock: disk encryption keys are evicted from RAM and the data
# partition is sealed again. This is the strongest anti-forensic control
# available without GrapheneOS itself.
screen_is_off() {
  dumpsys power 2>/dev/null | grep -qE 'mWakefulness=(Asleep|Dozing)'
}

device_is_locked() {
  dumpsys window 2>/dev/null | grep -qE 'mDreamingLockscreen=true|showing=true'
}

off_ticks=0
TICK=60

while true; do
  sleep "$TICK"

  if screen_is_off; then
    off_ticks=$((off_ticks + 1))
  else
    off_ticks=0
    continue
  fi

  off_minutes=$((off_ticks * TICK / 60))

  if [ "$RADIO_IDLE_MINUTES" -gt 0 ] && [ "$off_minutes" -ge "$RADIO_IDLE_MINUTES" ]; then
    if [ "$(settings get global wifi_on 2>/dev/null)" = "1" ]; then
      svc wifi disable >/dev/null 2>&1
      log "wifi off after ${off_minutes}m idle"
    fi
    if [ "$(settings get global bluetooth_on 2>/dev/null)" = "1" ]; then
      svc bluetooth disable >/dev/null 2>&1
      log "bluetooth off after ${off_minutes}m idle"
    fi
  fi

  if [ "$REBOOT_IDLE_HOURS" -gt 0 ]; then
    limit=$((REBOOT_IDLE_HOURS * 60))
    if [ "$off_minutes" -ge "$limit" ] && device_is_locked; then
      log "rebooting to BFU after ${off_minutes}m locked"
      sync
      svc power reboot 2>/dev/null || reboot
      exit 0
    fi
  fi
done
