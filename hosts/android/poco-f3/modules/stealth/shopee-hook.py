#!/usr/bin/env python3
"""
Shopee hook loader — spawns com.shopee.id under Frida with the bypass script.

Prerequisites:
  adb shell su -c 'frida-start'
  adb forward tcp:29170 tcp:29170

Usage:
  python3 shopee-hook.py                    # just bypass, monitor 120s
  python3 shopee-hook.py trace-api          # also trace API calls
"""

import frida
import time
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BYPASS_JS = os.path.join(SCRIPT_DIR, "shopee-bypass.js")
PORT = 29170
PACKAGE = "com.shopee.id"
DURATION = 120

def on_message(msg, data):
    if msg["type"] == "send":
        payload = msg["payload"]
        if isinstance(payload, dict) and payload.get("type") == "status":
            print(f"  [{payload['alive']}s] threads={payload['threads']}")
        else:
            print(f"[send] {payload}")
    elif msg["type"] == "log":
        print(msg["payload"])
    elif msg["type"] == "error":
        print(f"[ERROR] {msg.get('description', msg)}")

def main():
    print(f"[*] Connecting to 127.0.0.1:{PORT}...")
    device = frida.get_device_manager().add_remote_device(f"127.0.0.1:{PORT}")
    print(f"[*] Device: {device.name}")

    print(f"[*] Spawning {PACKAGE}...")
    pid = device.spawn([PACKAGE])
    session = device.attach(pid)

    with open(BYPASS_JS) as f:
        js = f.read()

    script = session.create_script(js, runtime="v8")
    script.on("message", on_message)
    script.load()

    print(f"[*] Resuming main thread (PID {pid})...")
    device.resume(pid)

    print(f"[*] Monitoring for {DURATION}s (Ctrl+C to stop)...")
    try:
        for _ in range(DURATION):
            time.sleep(1)
    except KeyboardInterrupt:
        pass

    print("[*] Detaching...")
    session.detach()

if __name__ == "__main__":
    main()
