#!/usr/bin/env bash
# Deploy the #poco-f3 home-manager workstation shell (zsh + starship + neovim +
# cli.nix) onto the phone, natively on /nix, no proot.
#
# Why this exists instead of `home-manager switch`: the phone (5.5 GB RAM) cannot
# run the heavy nix work — `nix-env -i home-manager-path` (the buildEnv that unions
# ~1108 packages) hangs indefinitely on-device. So we build the activationPackage on
# the Colima aarch64-linux VM, copy the closure to the phone, then activate WITHOUT
# nix-env -i: point the profile straight at the pre-built home-manager-path with
# `nix-env --set` (zero build) and hand-link the generation's dotfiles.
#
#   bash hosts/android/poco-f3/hm-deploy.sh
#
# Prereqs: Colima running, phone on adb with KernelSU root, nixbind module active.
set -euo pipefail

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mFAIL: %s\033[0m\n' "$*" >&2; exit 1; }

REPO_VM=/Users/ms/Development/infra.msdqn.dev   # repo path as seen inside the VM
WORK=/Users/ms/kbuild                            # Mac<->VM shared scratch
CLOSURE="$WORK/hm-closure.gz"
HOME_ON_PHONE=/data/local/nixhome

vm() { colima ssh -- bash -lc "$1"; }

say "1/5 build activationPackage on Colima (aarch64-linux)"
colima status >/dev/null 2>&1 || die "Colima is not running (colima start)"
GEN=$(vm "
  cd $REPO_VM
  df -k /nix | awk 'NR==2 && \$4 < 8000000 {print \"gc\"}' | grep -q gc && nix-collect-garbage -d >/dev/null 2>&1 || true
  nix build .#homeConfigurations.poco-f3.activationPackage --no-link --print-out-paths
") || die "build failed"
[ -n "$GEN" ] || die "no activationPackage path"
say "built $GEN"

say "2/5 export closure -> $CLOSURE"
vm "nix-store --export \$(nix-store -qR $GEN) | gzip -6 > $CLOSURE"

say "3/5 push closure to phone"
adb wait-for-device
dev=$(adb shell getprop ro.product.device | tr -d '\r'); [ "$dev" = "alioth" ] || die "device '$dev' != alioth"
adb shell 'su -c "echo ok"' >/dev/null 2>&1 || die "no KernelSU root"
adb push "$CLOSURE" /data/local/tmp/hm-closure.gz >/dev/null

HMPATH=$(vm "readlink -f $GEN/home-path")
[ -n "$HMPATH" ] || die "cannot resolve home-path"

say "4/5 import + activate on phone (nix-env --set, no build)"
cat >/tmp/poco-hm-activate.sh <<PHONESH
#!/system/bin/sh
set -e
. /nix/etc/profile.sh
export HOME=$HOME_ON_PHONE USER=root
GEN=$GEN
HMPATH=$HMPATH
PROF=/nix/var/nix/profiles/per-user/root/profile

gzip -dc /data/local/tmp/hm-closure.gz | nix-store --import >/dev/null
rm -f /data/local/tmp/hm-closure.gz

# Point the profile at the pre-built buildEnv directly — nix-env -i hangs on-device.
nix-env --profile "\$PROF" --set "\$HMPATH"
rm -rf "\$HOME/.nix-profile"; ln -sfn "\$PROF" "\$HOME/.nix-profile"

# Hand-link the generation's dotfiles into HOME (home-manager's linkGeneration
# step depends on the nix-env step that we bypassed).
HF="\$GEN/home-files"
( cd "\$HF"
  find . -type d | while IFS= read -r d; do [ "\$d" = . ] || mkdir -p "\$HOME/\${d#./}"; done
  find . \\( -type f -o -type l \\) | while IFS= read -r f; do ln -sfn "\$HF/\${f#./}" "\$HOME/\${f#./}"; done )

# glibc getpwuid(0) needs a real passwd/group (Android's are empty). nixbind's
# post-fs-data binds these every boot; create the sources and bind now.
mkdir -p "\$HOME/etc"
printf 'root:x:0:0:root:%s:%s/.nix-profile/bin/zsh\n' "\$HOME" "\$HOME" > "\$HOME/etc/passwd"
printf 'root:x:0:\nnixbld:x:30000:\n' > "\$HOME/etc/group"
mountpoint -q /etc/passwd || mount --bind "\$HOME/etc/passwd" /etc/passwd
mountpoint -q /etc/group  || mount --bind "\$HOME/etc/group"  /etc/group

# Termux: launch -> su -> native nix env -> zsh login shell (starship prompt).
THOME=/data/data/com.termux/files/home
if [ -d "\$THOME" ]; then
  cat > "\$THOME/.bashrc" <<'RC'
if [ -z "\$NIX_ENTERED" ] && [ "\$(id -u)" -ge 10000 ]; then
  if su -c 'true' 2>/dev/null; then
    export NIX_ENTERED=1
    exec su -c 'export NIX_ENTERED=1 HOME=/data/local/nixhome; . /nix/etc/profile.sh; exec /data/local/nixhome/.nix-profile/bin/zsh -l'
  else
    echo "[nix] Grant Termux root in KernelSU Next -> Superuser, then reopen."
  fi
fi
RC
  chown "\$(stat -c %u /data/data/com.termux)":"\$(stat -c %u /data/data/com.termux)" "\$THOME/.bashrc"
fi

echo "ACTIVATE_OK zsh=\$(\$HOME/.nix-profile/bin/zsh --version 2>&1)"
PHONESH
adb push /tmp/poco-hm-activate.sh /data/local/tmp/poco-hm-activate.sh >/dev/null
adb shell "su -c 'sh /data/local/tmp/poco-hm-activate.sh'" || die "activation failed"

say "5/5 done"
cat <<EOF

The workstation shell is live at $HOME_ON_PHONE (zsh + starship + neovim + cli).
Grant Termux root once (KernelSU Next -> Superuser -> Termux), then open Termux —
it drops straight into the native nix zsh. Re-run this script to update the config.
EOF
