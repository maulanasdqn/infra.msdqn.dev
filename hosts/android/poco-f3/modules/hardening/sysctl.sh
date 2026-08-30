#!/system/bin/sh
# Runtime kernel hardening, applied early at post-fs-data.
#
# crDroid already ships the important compile-time hardening on this kernel
# (KASLR, HARDENED_USERCOPY, SLAB_FREELIST_RANDOM/HARDENED, STACKPROTECTOR_STRONG,
# STRICT_KERNEL_RWX, INIT_ON_ALLOC, BUG_ON_DATA_CORRUPTION), so what is left is
# the sysctl surface, which ships wide open.

set_sysctl() {
  cur=$(sysctl -n "$1" 2>/dev/null) || return 0
  [ -z "$cur" ] && return 0
  [ "$cur" = "$2" ] && return 0
  sysctl -w "$1=$2" >/dev/null 2>&1
}

# perf_event_paranoid ships at -1, meaning unprivileged processes get full perf
# access. That is a long-standing local privilege-escalation primitive; 3 denies
# it entirely.
set_sysctl kernel.perf_event_paranoid 3

# Keep kernel pointers and the ring buffer away from unprivileged readers.
set_sysctl kernel.kptr_restrict 2
set_sysctl kernel.dmesg_restrict 1

# eBPF hardening is deliberately absent. Both of these BRICK THE BOOT here:
#
#   kernel.unprivileged_bpf_disabled=1
#   net.core.bpf_jit_harden=2
#
# Android is not a normal Linux box. netd loads eBPF programs through
# /apex/com.android.tethering/lib64/libnetd_updatable.so for network accounting
# and firewalling, and it does so over the unprivileged bpf() path. Restrict
# that and libnetd_updatable_init aborts, netd crash-loops, and the device never
# finishes booting: system_server starts but the settings service never
# registers, so the device looks alive over adb while being unusable.
#
# Verified the hard way on this device, twice. Recovery is:
#   adb shell su -c 'touch /data/adb/modules/hardening/disable' && adb reboot
#
# Do not "harden" these without testing a full boot first.

set_sysctl kernel.randomize_va_space 2
set_sysctl kernel.sysrq 0

# Classic symlink/hardlink TOCTOU protections in world-writable dirs.
set_sysctl fs.protected_symlinks 1
set_sysctl fs.protected_hardlinks 1
set_sysctl fs.protected_fifos 2
set_sysctl fs.protected_regular 2

set_sysctl net.ipv4.conf.all.rp_filter 1
set_sysctl net.ipv4.conf.default.rp_filter 1
set_sysctl net.ipv4.conf.all.send_redirects 0
set_sysctl net.ipv4.conf.default.send_redirects 0
set_sysctl net.ipv4.conf.all.accept_redirects 0
set_sysctl net.ipv4.conf.default.accept_redirects 0
set_sysctl net.ipv4.conf.all.accept_source_route 0
set_sysctl net.ipv4.conf.all.secure_redirects 0
set_sysctl net.ipv4.tcp_syncookies 1
set_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1
set_sysctl net.ipv4.tcp_rfc1337 1

set_sysctl net.ipv6.conf.all.accept_redirects 0
set_sysctl net.ipv6.conf.default.accept_redirects 0
set_sysctl net.ipv6.conf.all.accept_source_route 0

# IPv6 privacy extensions: prefer temporary, rotating addresses over ones
# derived from the MAC, so the address does not follow the device between
# networks.
set_sysctl net.ipv6.conf.all.use_tempaddr 2
set_sysctl net.ipv6.conf.default.use_tempaddr 2
