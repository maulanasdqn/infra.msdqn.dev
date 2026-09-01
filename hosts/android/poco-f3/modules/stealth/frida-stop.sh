#!/system/bin/sh
# Stop stealth frida-server and clean up the renamed binary.
DIR=/data/local/tmp/.cache

pkill -f "$DIR/" 2>/dev/null
rm -rf "$DIR" 2>/dev/null
echo "frida stopped"
