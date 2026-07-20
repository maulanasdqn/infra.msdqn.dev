{
  pkgs,
  lib,
  username,
  enableTilingWM,
  ...
}:
let
  sketchybarPkg = pkgs.sketchybar;
  # Workspace indicator — responds to aerospace_workspace_change event.
  # $NAME  is set by sketchybar (e.g. "space.3")
  # $AEROSPACE_FOCUSED_WORKSPACE is passed via the trigger payload
  spaceScript = pkgs.writeShellScript "sb-space" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    WS_NUM="''${NAME#space.}"
    if [ "$AEROSPACE_FOCUSED_WORKSPACE" = "$WS_NUM" ]; then
      sketchybar --animate overshoot 15 --set "$NAME" \
        background.color=0xffc4a7e7 \
        background.height=12 \
        background.corner_radius=6 \
        icon.padding_left=10 \
        icon.padding_right=10
    else
      sketchybar --animate overshoot 15 --set "$NAME" \
        background.color=0x30e0def4 \
        background.height=8 \
        background.corner_radius=4 \
        icon.padding_left=1 \
        icon.padding_right=1
    fi
  '';

  clockHScript = pkgs.writeShellScript "sb-clock-h" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_h label="$(date +'%H')"
  '';
  clockMScript = pkgs.writeShellScript "sb-clock-m" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_m label="$(date +'%M')"
  '';
  clockDateScript = pkgs.writeShellScript "sb-clock-date" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_date label="$(date +'%d')"
  '';
  clockMonthScript = pkgs.writeShellScript "sb-clock-month" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_month label="$(date +'%b')"
  '';

  # CPU load. Single instantaneous `top` sample (user+sys), normalised to 100%
  # across all cores. `-n 0` skips the process list so this stays cheap. Colour
  # ramps foam → gold (≥50%) → love (≥85%). Hardcode /usr/bin/top: the procps
  # `top` on PATH (from nixpkgs) is a Linux build that can't sample on macOS.
  cpuScript = pkgs.writeShellScript "sb-cpu" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    USED=$(/usr/bin/top -l 1 -n 0 2>/dev/null | awk '/CPU usage/ {u=$3; s=$5; gsub(/%/,"",u); gsub(/%/,"",s); printf "%.0f", u+s}')
    USED=''${USED:-0}
    if [ "$USED" -ge 85 ]; then
      COLOR=0xffeb6f92   # love
    elif [ "$USED" -ge 50 ]; then
      COLOR=0xfff6c177   # gold
    else
      COLOR=0xff9ccfd8   # foam
    fi
    sketchybar --set cpu icon="󰻠" icon.color="$COLOR" label="''${USED}%"
  '';

  # RAM usage. Activity-Monitor-style "memory used" = (active + wired +
  # compressed) pages over hw.memsize, shown as a percentage. Pure vm_stat +
  # sysctl reads, cheap at a 5s refresh. Colour ramps foam → gold (≥70%) →
  # love (≥90%).
  ramScript = pkgs.writeShellScript "sb-ram" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    TOTAL=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    PCT=$(vm_stat 2>/dev/null | awk -v total="$TOTAL" '
      /page size of/ {page=$8}
      /Pages active/ {a=$3}
      /Pages wired down/ {w=$4}
      /Pages occupied by compressor/ {c=$5}
      END {
        gsub(/\./,"",a); gsub(/\./,"",w); gsub(/\./,"",c);
        if (total>0) printf "%.0f", (a+w+c)*page*100/total; else printf "0"
      }')
    PCT=''${PCT:-0}
    if [ "$PCT" -ge 90 ]; then
      COLOR=0xffeb6f92   # love
    elif [ "$PCT" -ge 70 ]; then
      COLOR=0xfff6c177   # gold
    else
      COLOR=0xff9ccfd8   # foam
    fi
    sketchybar --set ram icon="󰍛" icon.color="$COLOR" label="''${PCT}%"
  '';

  # Swap-pressure early-warning. Uses the kernel's own pressure level
  # (kern.memorystatus_vm_pressure_level: 1=normal 2=warn 4=critical) for the
  # icon colour, and live swap usage (vm.swapusage) as the label — swap growing
  # is the concrete "about to lag" signal on this machine. Both are instant
  # sysctl reads, so this stays cheap at a 5s refresh.
  swapScript = pkgs.writeShellScript "sb-swap" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    LEVEL=$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null || echo 1)
    SWAP_M=$(sysctl -n vm.swapusage 2>/dev/null | sed -n 's/.*used = \([0-9.]*\)M.*/\1/p')
    SWAP_M=''${SWAP_M:-0}
    INT=''${SWAP_M%.*}
    if [ "''${INT:-0}" -ge 1024 ]; then
      LABEL=$(awk "BEGIN{printf \"%.1fG\", $SWAP_M/1024}")
    else
      LABEL="''${INT:-0}M"
    fi
    case "$LEVEL" in
      2) COLOR=0xfff6c177 ;;  # warn     — gold
      4) COLOR=0xffeb6f92 ;;  # critical — love/red
      *) COLOR=0xff9ccfd8 ;;  # normal   — foam
    esac
    sketchybar --set swap icon="󰓡" icon.color="$COLOR" label="$LABEL"
  '';

  wifiScript = pkgs.writeShellScript "sb-network" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    # Use the active default-route interface, not a hardcoded en0 — the Mac mini
    # is on en1 (Wi-Fi), MacBooks vary. Pick whichever carries the default route.
    IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
    IP=""
    [ -n "$IFACE" ] && IP=$(ipconfig getifaddr "$IFACE" 2>/dev/null)
    if [ -n "$IP" ]; then
      WIFI_DEV=$(networksetup -listallhardwareports 2>/dev/null \
        | awk '/Hardware Port: Wi-Fi/{getline; print $2}')
      if [ "$IFACE" = "$WIFI_DEV" ]; then
        sketchybar --set wifi icon="󰖩" icon.color=0xff9ccfd8 label="$IP"
      else
        sketchybar --set wifi icon="󰈀" icon.color=0xff9ccfd8 label="$IP"
      fi
    else
      sketchybar --set wifi icon="󰤮" icon.color=0x886e6a86 label="off"
    fi
  '';

  # Event-driven (volume_change), so this fires only when the volume/mute
  # actually changes — not on a poll. One osascript call returns both the level
  # and the mute state (two calls = two AppleScript runtime spawns, the single
  # most expensive repeated process churn on this machine).
  volumeScript = pkgs.writeShellScript "sb-volume" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    RES=$(osascript -e "set s to (get volume settings)" \
                    -e "return (output volume of s as text) & \",\" & (output muted of s as text)" 2>/dev/null)
    VOL="''${RES%%,*}"
    MUTED="''${RES##*,}"
    if [ "$MUTED" = "true" ]; then
      sketchybar --set volume icon="󰖁" icon.color=0x886e6a86 label="—"
    else
      sketchybar --set volume icon="󰕾" icon.color=0xff9ccfd8 label="''${VOL}"
    fi
  '';

  brightnessScript = pkgs.writeShellScript "sb-brightness" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    BRIGHT=$(python3 -c "
import ctypes, sys
ds = ctypes.CDLL('/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices')
ds.DisplayServicesGetBrightness.restype = ctypes.c_int
val = ctypes.c_float()
ret = ds.DisplayServicesGetBrightness(1, ctypes.byref(val))
if ret != 0:
    sys.exit(1)
print(int(val.value * 100))
" 2>/dev/null)
    # No controllable internal display (Mac mini → external-only, ret!=0) — hide it.
    if [ -z "$BRIGHT" ]; then
      sketchybar --set brightness drawing=off
      exit 0
    fi
    sketchybar --set brightness drawing=on icon="󰖨" icon.color=0xfff6c177 label="''${BRIGHT}"
  '';

  batteryScript = pkgs.writeShellScript "sb-battery" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    # Desktops (Mac mini) have no internal battery — hide the item entirely.
    if ! pmset -g batt 2>/dev/null | grep -q "InternalBattery"; then
      sketchybar --set battery drawing=off
      exit 0
    fi
    BATT=$(pmset -g batt 2>/dev/null | grep -o "[0-9]*%" | head -1 | tr -d "%")
    AC=$(pmset -g batt 2>/dev/null | grep -c "AC Power" || true)
    if [ "$AC" -gt 0 ]; then
      sketchybar --set battery icon="󱐋" icon.color=0xff9ccfd8 label="''${BATT}"
    elif [ "''${BATT:-100}" -le 15 ]; then
      sketchybar --set battery icon="󱐋" icon.color=0xffeb6f92 label="''${BATT}"
    else
      sketchybar --set battery icon="󱐋" icon.color=0xfff6c177 label="''${BATT}"
    fi
  '';

  sketchybarrc = pkgs.writeShellScript "sketchybarrc" ''
    # Rosé Pine — sketchybar top bar (mirrors eww vertical bar)

    sketchybar --bar \
      position=top \
      height=40 \
      blur_radius=20 \
      color=0xdd191724 \
      border_width=1 \
      border_color=0x30c4a7e7 \
      corner_radius=16 \
      margin=12 \
      y_offset=8 \
      topmost=window

    sketchybar --default \
      updates=when_shown \
      icon.font="JetBrainsMono Nerd Font Mono:Regular:16.0" \
      icon.color=0xffc4a7e7 \
      icon.padding_left=4 \
      icon.padding_right=4 \
      label.font="JetBrainsMono Nerd Font:SemiBold:13.0" \
      label.color=0xffe0def4 \
      label.padding_left=4 \
      label.padding_right=4

    # Nix logo
    sketchybar --add item logo left \
      --set logo \
        icon="" \
        icon.color=0xffc4a7e7 \
        icon.font="JetBrainsMono Nerd Font Mono:Regular:22.0" \
        icon.padding_left=16 \
        icon.padding_right=12 \
        label.drawing=off

    # Register Aerospace workspace change event
    sketchybar --add event aerospace_workspace_change

    # Workspaces 1–6 (matches eww)
    for i in 1 2 3 4 5 6; do
      sketchybar --add item "space.''${i}" left \
        --set "space.''${i}" \
          script="${spaceScript}" \
          click_script="aerospace workspace ''${i}" \
          icon.drawing=off \
          label.drawing=off \
          background.color=0x30e0def4 \
          background.corner_radius=4 \
          background.height=8 \
          icon=" " \
          icon.font="JetBrainsMono Nerd Font:Regular:1.0" \
          icon.drawing=on \
          icon.padding_left=1 \
          icon.padding_right=1 \
          icon.color=0x00000000 \
          label.drawing=off \
          padding_left=6 \
          padding_right=6 \
        --subscribe "space.''${i}" aerospace_workspace_change
    done

    # Status items — consistent icon+label spacing
    sketchybar --add item wifi right \
      --set wifi \
        update_freq=10 \
        script="${wifiScript}" \
        icon="󰖩" \
        icon.color=0xff9ccfd8 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    sketchybar --add item volume right \
      --set volume \
        script="${volumeScript}" \
        icon="󰕾" \
        icon.color=0xff9ccfd8 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10 \
      --subscribe volume volume_change

    # Poll slowly (30s) as a fallback, but mainly react to brightness_change —
    # python3 startup is heavy, so we want this firing on change, not every 5s.
    sketchybar --add item brightness right \
      --set brightness \
        update_freq=30 \
        script="${brightnessScript}" \
        icon="󰖨" \
        icon.color=0xfff6c177 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10 \
      --subscribe brightness brightness_change

    sketchybar --add item battery right \
      --set battery \
        update_freq=30 \
        script="${batteryScript}" \
        icon="󱐋" \
        icon.color=0xfff6c177 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    # Swap pressure — icon colour = kernel pressure level, label = swap used.
    # Added first so the cpu/ram/swap block reads left→right CPU · RAM · SWAP.
    sketchybar --add item swap right \
      --set swap \
        update_freq=5 \
        script="${swapScript}" \
        icon="󰓡" \
        icon.color=0xff9ccfd8 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    # RAM usage — (active + wired + compressed) / total, as a percentage
    sketchybar --add item ram right \
      --set ram \
        update_freq=5 \
        script="${ramScript}" \
        icon="󰍛" \
        icon.color=0xff9ccfd8 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    # CPU load — user + sys, normalised to 100% across all cores
    sketchybar --add item cpu right \
      --set cpu \
        update_freq=10 \
        script="${cpuScript}" \
        icon="󰻠" \
        icon.color=0xff9ccfd8 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    # Clock — H · M   date Mon
    sketchybar --add item clock_month right \
      --set clock_month \
        update_freq=1800 \
        script="${clockMonthScript}" \
        icon.drawing=off \
        label.font="JetBrainsMono Nerd Font:Bold:13.0" \
        label.color=0xff908caa \
        label.padding_left=2 \
        label.padding_right=18

    sketchybar --add item clock_date right \
      --set clock_date \
        update_freq=1800 \
        script="${clockDateScript}" \
        icon.drawing=off \
        label.font="JetBrainsMono Nerd Font:Bold:16.0" \
        label.color=0xffe0def4 \
        label.padding_left=10 \
        label.padding_right=2

    sketchybar --add item clock_m right \
      --set clock_m \
        update_freq=5 \
        script="${clockMScript}" \
        icon.drawing=off \
        label.font="JetBrainsMono Nerd Font:Bold:18.0" \
        label.color=0xffc4a7e7 \
        label.padding_left=2 \
        label.padding_right=2

    sketchybar --add item clock_sep right \
      --set clock_sep \
        icon.drawing=off \
        label="·" \
        label.font="JetBrainsMono Nerd Font:Bold:18.0" \
        label.color=0xffeb6f92 \
        label.padding_left=4 \
        label.padding_right=4

    sketchybar --add item clock_h right \
      --set clock_h \
        update_freq=5 \
        script="${clockHScript}" \
        icon.drawing=off \
        label.font="JetBrainsMono Nerd Font:Bold:18.0" \
        label.color=0xffebbcba \
        label.padding_left=18 \
        label.padding_right=0

    sketchybar --update

    # Trigger initial workspace highlight
    INIT_WS=$(aerospace list-workspaces --focused 2>/dev/null || echo "1")
    sketchybar --trigger aerospace_workspace_change AEROSPACE_FOCUSED_WORKSPACE="$INIT_WS"
  '';
in
lib.mkIf enableTilingWM {
  environment.systemPackages = [ sketchybarPkg ];

  system.activationScripts.postActivation.text = ''
    mkdir -p /usr/local/bin
    rm -f /usr/local/bin/sketchybar
    cp ${sketchybarPkg}/bin/sketchybar /usr/local/bin/sketchybar
    chmod +x /usr/local/bin/sketchybar
    echo "Copied sketchybar to /usr/local/bin"
  '';

  home-manager.users.${username} = {
    home.file.".config/sketchybar/sketchybarrc" = {
      source = sketchybarrc;
      executable = true;
    };
  };

  launchd.user.agents.sketchybar = {
    serviceConfig = {
      # Point at the immutable nix store binary, NOT /usr/local/bin/sketchybar.
      # The /usr/local copy is rm -f'd and re-cp'd at every boot by the
      # activate-system daemon; if this agent's RunAtLoad fires during that
      # window it execs a missing/partial binary → blank bar after reboot.
      # (The /usr/local copy still exists below for the aerospace trigger +
      # bare `sketchybar` calls inside the config, both of which run later.)
      #
      # But the store path has its own boot race: /nix is a separate APFS
      # volume mounted by the darwin-store daemon, and this agent's RunAtLoad
      # can fire before that mount lands. launchd then fails the spawn with
      # EX_CONFIG (78) and penalty-boxes the agent — KeepAlive never retries,
      # so the bar stays dead for the whole session. Wrap in /bin/sh (root
      # volume, always present) + /bin/wait4path, which blocks until the
      # store path is reachable, then exec. Same pattern org.nixos.nix-daemon
      # uses for exactly this reason.
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path ${sketchybarPkg}/bin/sketchybar && exec ${sketchybarPkg}/bin/sketchybar"
      ];
      EnvironmentVariables = {
        PATH = "/usr/local/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/sketchybar.out.log";
      StandardErrorPath = "/tmp/sketchybar.err.log";
    };
  };
}
