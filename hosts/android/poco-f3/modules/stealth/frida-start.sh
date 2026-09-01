#!/system/bin/sh
# Start frida-server with stealth wrapping: renamed binary, non-standard
# port, localhost-only. Run as root (via su or nix-enter).
#
# Place the frida-server binary first (use strongR-frida-android for full
# stealth — it obfuscates thread names and agent strings that stock Frida
# leaks into the target process):
#
#   adb push frida-server /data/local/tmp/
#   adb shell su -c 'mkdir -p /data/adb/frida && mv /data/local/tmp/frida-server /data/adb/frida/ && chmod 755 /data/adb/frida/frida-server'
#
# Then:
#   frida-start           # default port 29170
#   frida-start 31337     # custom port

PORT=${1:-29170}
SRC=/data/adb/frida/frida-server
DIR=/data/local/tmp/.cache

if [ ! -x "$SRC" ]; then
  echo "frida-server not found at $SRC"
  echo "push it first: adb push frida-server /data/local/tmp/"
  echo "then: su -c 'mkdir -p /data/adb/frida && mv /data/local/tmp/frida-server /data/adb/frida/ && chmod 755 /data/adb/frida/frida-server'"
  exit 1
fi

pkill -f "$DIR/" 2>/dev/null
rm -rf "$DIR" 2>/dev/null
sleep 1

NAME=$(cat /proc/sys/kernel/random/uuid | cut -c1-12)
mkdir -p "$DIR"
cp "$SRC" "$DIR/$NAME"
chmod 755 "$DIR/$NAME"

nohup "$DIR/$NAME" -l "127.0.0.1:$PORT" </dev/null >/dev/null 2>&1 &

sleep 1
if kill -0 $! 2>/dev/null; then
  echo "frida running as '$NAME' (PID $!) on 127.0.0.1:$PORT"
  echo "from host:"
  echo "  adb forward tcp:$PORT tcp:$PORT"
  echo "  frida -H 127.0.0.1:$PORT -U -f com.shopee.id"
else
  echo "frida-server failed to start — check logcat"
  exit 1
fi
