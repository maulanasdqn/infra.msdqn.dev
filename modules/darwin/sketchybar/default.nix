{
  pkgs,
  lib,
  username,
  enableTilingWM,
  ...
}:
let
  sketchybarPkg = pkgs.sketchybar;

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
    sketchybar --bar \
      position=top \
      height=34 \
      blur_radius=0 \
      color=0x00000000 \
      border_width=0 \
      corner_radius=0 \
      margin=0 \
      padding_left=12 \
      padding_right=12 \
      y_offset=8 \
      topmost=window

    ISLAND="background.drawing=on \
      background.color=0xee191724 \
      background.corner_radius=14 \
      background.height=30 \
      background.border_width=1 \
      background.border_color=0x30c4a7e7"

    GAP="background.drawing=off icon.drawing=off label.drawing=off"

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

    NIX_LOGO=$(printf '\uf313')

    sketchybar --add item logo left \
      --set logo \
        icon="$NIX_LOGO" \
        icon.color=0xffc4a7e7 \
        icon.font="JetBrainsMono Nerd Font Mono:Regular:22.0" \
        icon.padding_left=14 \
        icon.padding_right=14 \
        label.drawing=off

    sketchybar --add item gap.1 left \
      --set gap.1 width=10 $GAP

    sketchybar --add item ws_pad.l left \
      --set ws_pad.l width=6 $GAP

    sketchybar --add event aerospace_workspace_change

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

    sketchybar --add item ws_pad.r left \
      --set ws_pad.r width=6 $GAP

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

    sketchybar --add item gap.2 right \
      --set gap.2 width=10 $GAP

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

    sketchybar --add item gap.3 right \
      --set gap.3 width=10 $GAP

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

    sketchybar --add item gap.4 right \
      --set gap.4 width=10 $GAP

    sketchybar --add item clock_month right \
      --set clock_month \
        update_freq=1800 \
        script="${clockMonthScript}" \
        icon.drawing=off \
        label.font="JetBrainsMono Nerd Font:Bold:13.0" \
        label.color=0xff908caa \
        label.padding_left=2 \
        label.padding_right=12

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
        label.padding_left=12 \
        label.padding_right=0

    sketchybar \
      --add bracket is_logo   logo \
      --add bracket is_spaces ws_pad.l space.1 space.2 space.3 space.4 space.5 space.6 ws_pad.r \
      --add bracket is_clock  clock_h clock_sep clock_m clock_date clock_month \
      --add bracket is_sys    cpu ram swap \
      --add bracket is_hw     battery brightness volume \
      --add bracket is_net    wifi

    for b in is_logo is_spaces is_clock is_sys is_hw is_net; do
      sketchybar --set "$b" $ISLAND
    done

    sketchybar --update

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
