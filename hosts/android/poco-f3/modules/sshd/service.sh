#!/system/bin/sh
# Start OpenSSH at late_start, in init's persistent context (a daemon backgrounded
# from a transient su session gets reaped; this one survives).
#
# Bound to 127.0.0.1:8022, key-only, no passwords. Reach it from a computer with:
#   adb forward tcp:8022 tcp:8022
#   ssh -p 8022 root@127.0.0.1
# so nothing is ever exposed on the network.

SSHDIR=/data/ssh
LOGIN=@login@

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 5; done
sleep 15

. /nix/etc/profile.sh

# Prefer the openssh already installed in the default profile (fast, offline).
# Fall back to fetching it from nixpkgs on a fresh phone that lacks it.
SSHD="$(readlink -f /nix/var/nix/profiles/default/bin/sshd 2>/dev/null)"
[ -x "$SSHD" ] || SSHD="$(nix build --no-link --print-out-paths nixpkgs#openssh 2>/dev/null)/bin/sshd"
[ -x "$SSHD" ] || exit 0

mkdir -p "$SSHDIR"
chmod 700 "$SSHDIR"

[ -f "$SSHDIR/ssh_host_ed25519_key" ] || \
  ssh-keygen -t ed25519 -N "" -f "$SSHDIR/ssh_host_ed25519_key" >/dev/null 2>&1

cat > "$SSHDIR/authorized_keys" <<KEYS
@authorizedKey@
KEYS
chmod 600 "$SSHDIR/authorized_keys"

cat > "$LOGIN" <<'LOGIN_SH'
#!/system/bin/sh
export HOME=/data/local/nixhome
. /nix/etc/profile.sh
cd "$HOME" 2>/dev/null
# Honour a sent command (ssh host 'cmd'); otherwise an interactive login shell.
# A bare `exec sh -l` would swallow the command and hang -tt sessions.
if [ -n "$SSH_ORIGINAL_COMMAND" ]; then
  exec /system/bin/sh -c "$SSH_ORIGINAL_COMMAND"
else
  exec /system/bin/sh -l
fi
LOGIN_SH
chmod 0755 "$LOGIN"

cat > "$SSHDIR/sshd_config" <<CONF
Port 8022
ListenAddress 127.0.0.1
HostKey $SSHDIR/ssh_host_ed25519_key
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile $SSHDIR/authorized_keys
ForceCommand $LOGIN
PidFile $SSHDIR/sshd.pid
StrictModes no
CONF

pkill -f "$SSHDIR/sshd_config" 2>/dev/null
setsid "$SSHD" -f "$SSHDIR/sshd_config" -E "$SSHDIR/sshd.log" </dev/null >/dev/null 2>&1 &
