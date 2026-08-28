#!/system/bin/sh
# glibc OpenSSH (from the native nix store) needs a few POSIX things Android
# does not provide. Create them early, before the daemon starts at late_start.
#
#   /etc/passwd + /etc/group  - Android has neither, so getpwuid(0) fails and
#                               sshd cannot resolve root or its privsep user.
#   /var/empty                - OpenSSH's privilege-separation dir is compiled
#                               into the binary as /var/empty; it ignores the
#                               passwd home field, so the real path must exist.
#
# Both live on the read-only root fs, writable only because dm-verity is off.

mount -o remount,rw / || exit 0

[ -f /system/etc/passwd ] || cat > /system/etc/passwd <<PW
root:x:0:0:root:/data/local/nixhome:/system/bin/sh
sshd:x:9999:9999:sshd privsep:/var/empty:/system/bin/nologin
PW
chmod 0644 /system/etc/passwd

[ -f /system/etc/group ] || cat > /system/etc/group <<GR
root:x:0:
sshd:x:9999:
GR
chmod 0644 /system/etc/group

mkdir -p /var/empty
chmod 0755 /var/empty
chown 0:0 /var/empty

mount -o remount,ro /
