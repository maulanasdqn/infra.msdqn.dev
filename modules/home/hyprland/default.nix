{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./eww.nix
    ./wofi.nix
    ./theme.nix
    ./hypridle.nix
  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;

      settings = {
        "$base" = "rgb(191724)";
        "$surface" = "rgb(1f1d2e)";
        "$overlay" = "rgb(26233a)";
        "$muted" = "rgb(6e6a86)";
        "$subtle" = "rgb(908caa)";
        "$text" = "rgb(e0def4)";
        "$love" = "rgb(eb6f92)";
        "$gold" = "rgb(f6c177)";
        "$rose" = "rgb(ebbcba)";
        "$pine" = "rgb(31748f)";
        "$foam" = "rgb(9ccfd8)";
        "$iris" = "rgb(c4a7e7)";
        "$highlightMed" = "rgb(403d52)";

        monitor = [
          "eDP-1,2880x1800@90,0x0,1.33"
          "HDMI-A-1,1920x1080@60,auto,0.8"
          ",preferred,auto,1.0"
        ];

        exec-once = [
          "hyprctl setcursor Bibata-Modern-Classic 32"
          "swaybg -i /home/${username}/Downloads/2109.jpg -m fill"
          "eww open bar"
          "swayosd-server"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
        ];

        general = {
          gaps_in = 8;
          gaps_out = 16;
          border_size = 1;
          "col.active_border" = "$iris $rose 45deg";
          "col.inactive_border" = "$highlightMed";
          layout = "dwindle";
          allow_tearing = false;
        };

        decoration = {
          rounding = 16;
          blur = {
            enabled = true;
            size = 8;
            passes = 3;
            new_optimizations = true;
            xray = true;
            vibrancy = 0.17;
            popups = true;
          };
          shadow = {
            enabled = true;
            range = 20;
            render_power = 3;
            color = "rgba(0f0d1aee)";
          };
        };

        animations = {
          enabled = true;
          bezier = [
            "cute, 0.68, -0.55, 0.265, 1.55"
            "smooth, 0.25, 0.1, 0.25, 1"
            "bounce, 0.68, -0.6, 0.32, 1.6"
            "fadeBounce, 0.36, 0, 0.66, -0.56"
          ];
          animation = [
            "windows, 1, 5, bounce, slide"
            "windowsOut, 1, 5, cute, slide"
            "border, 1, 10, smooth"
            "borderangle, 1, 100, smooth, loop"
            "fade, 1, 5, smooth"
            "workspaces, 1, 5, smooth, slidefade 20%"
          ];
        };

        dwindle = {
          preserve_split = true;
          force_split = 2;
        };

        master = {
          new_status = "master";
        };

        input = {
          kb_layout = "us";
          kb_options = "caps:escape";
          follow_mouse = 1;
          sensitivity = 0.0;
          accel_profile = "adaptive";
          scroll_factor = 1.0;
          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
            scroll_factor = 0.2;
          };
        };

        device = [
          {
            name = "asup1303:00-093a:3003-touchpad";
            sensitivity = 0.0;
            scroll_factor = 0.2;
          }
          {
            name = "asup1303:00-093a:3003-mouse";
            enabled = false;
          }
        ];

        cursor = {
          default_monitor = "";
        };

        env = [
          "XCURSOR_THEME,Bibata-Modern-Classic"
          "XCURSOR_SIZE,32"
          "NIXOS_OZONE_WL,1"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          "MOZ_ENABLE_WAYLAND,1"
        ];

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        windowrule = [
          "float on, match:class ^(pavucontrol)$"
          "float on, match:class ^(nm-connection-editor)$"
          "float on, match:class ^(org.gnome.Calculator)$"
          "float on, match:title ^(Picture-in-Picture)$"
          "opacity 1.0 0.92, match:class ^(kitty)$"
          "opacity 1.0 0.92, match:class ^(Alacritty)$"
          "opacity 0.9, match:class ^(code)$"
        ];

        layerrule = [
          "blur on, ignore_alpha 0.3, match:namespace gtk-layer-shell"
          "blur on, ignore_alpha 0.3, match:namespace wofi"
        ];

        "$mod" = "SUPER";
        "$terminal" = "kitty";
        "$menu" = "wofi --show drun";
        "$browser" = "firefox";
        "$fileManager" = "nautilus";

        bind = [
          "$mod, Return, exec, $terminal"
          "$mod, Space, exec, $menu"
          "$mod, D, exec, $menu"
          "$mod, E, exec, $fileManager"
          "$mod, B, exec, $browser"

          "$mod SHIFT, Q, killactive"
          "$mod SHIFT, E, exit"
          "$mod, V, togglefloating"
          "$mod, F, fullscreen"
          "$mod, J, layoutmsg, togglesplit"
          "$mod SHIFT, B, exec, eww open --toggle bar"
          "$mod SHIFT, T, exec, fix-touchpad"
          "$mod SHIFT, H, exec, systemctl hibernate"

          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"

          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
          "SHIFT, Print, exec, grim - | wl-copy"

          "$mod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

          "$mod SHIFT, C, exec, hyprpicker -a"

          "$mod, X, exec, hyprlock"
          "$mod SHIFT, X, exec, caffeine"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bindel = [
          ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume +2"
          ", XF86AudioLowerVolume, exec, swayosd-client --output-volume -2"
        ];

        bindl = [
          ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
          ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
          ", switch:on:Lid Switch, exec, systemctl suspend"
        ];

        binde = [
          ", XF86MonBrightnessUp, exec, swayosd-client --brightness +2"
          ", XF86MonBrightnessDown, exec, swayosd-client --brightness -2"
        ];

        gesture = [
          "3, horizontal, workspace"
        ];
      };
    };

    home.file.".config/hypr/hyprlock.conf".text = ''
      general {
        disable_loading_bar = true
        grace = 0
        hide_cursor = true
        no_fade_in = false
      }

      background {
        monitor =
        path = ~/Downloads/2109.jpg
        blur_passes = 4
        blur_size = 9
        noise = 0.012
        contrast = 0.95
        brightness = 0.65
        vibrancy = 0.18
        vibrancy_darkness = 0.05
      }

      label {
        monitor =
        text = cmd[update:1000] echo "$(date +'%H:%M')"
        color = rgba(224, 222, 244, 0.95)
        font_size = 120
        font_family = JetBrainsMono Nerd Font ExtraBold
        position = 0, 240
        halign = center
        valign = center
        shadow_passes = 2
        shadow_size = 6
        shadow_color = rgba(0, 0, 0, 0.45)
      }

      label {
        monitor =
        text = cmd[update:30000] echo "$(date +'%A, %d %B %Y')"
        color = rgba(196, 167, 231, 0.90)
        font_size = 18
        font_family = JetBrainsMono Nerd Font Medium
        position = 0, 120
        halign = center
        valign = center
      }

      shape {
        monitor =
        size = 130, 130
        color = rgba(31, 29, 46, 0.55)
        rounding = -1
        border_size = 2
        border_color = rgba(196, 167, 231, 0.60)
        position = 0, -30
        halign = center
        valign = center
        shadow_passes = 2
        shadow_size = 4
        shadow_color = rgba(0, 0, 0, 0.35)
      }

      label {
        monitor =
        text = 󰀄
        color = rgba(196, 167, 231, 0.90)
        font_size = 64
        font_family = JetBrainsMono Nerd Font
        position = 0, -30
        halign = center
        valign = center
      }

      label {
        monitor =
        text = $USER
        color = rgba(224, 222, 244, 0.95)
        font_size = 16
        font_family = JetBrainsMono Nerd Font Bold
        position = 0, -135
        halign = center
        valign = center
      }

      input-field {
        monitor =
        size = 320, 52
        outline_thickness = 2
        dots_size = 0.26
        dots_spacing = 0.30
        dots_center = true
        dots_rounding = -1
        outer_color = rgba(196, 167, 231, 0.55)
        inner_color = rgba(31, 29, 46, 0.65)
        font_color = rgba(224, 222, 244, 0.95)
        fade_on_empty = false
        rounding = 26
        check_color = rgba(156, 207, 216, 0.85)
        fail_color = rgba(235, 111, 146, 0.85)
        fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
        placeholder_text = <span font_family="JetBrainsMono Nerd Font" foreground="##c4a7e7cc">  Enter password</span>
        hide_input = false
        position = 0, -200
        halign = center
        valign = center
        shadow_passes = 2
        shadow_size = 4
        shadow_color = rgba(0, 0, 0, 0.35)
      }

      label {
        monitor =
        text = cmd[update:60000] echo "  $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)%"
        color = rgba(196, 167, 231, 0.75)
        font_size = 12
        font_family = JetBrainsMono Nerd Font
        position = -20, 20
        halign = right
        valign = bottom
      }

      label {
        monitor =
        text = cmd[update:30000] echo "  $(nmcli -t -f active,ssid dev wifi | awk -F: '/^yes/{print $2; exit}' || echo 'offline')"
        color = rgba(196, 167, 231, 0.75)
        font_size = 12
        font_family = JetBrainsMono Nerd Font
        position = 20, 20
        halign = left
        valign = bottom
      }
    '';

    services.mako = {
      enable = true;
      settings = {
        background-color = "#1f1d2e";
        text-color = "#e0def4";
        border-color = "#c4a7e7";
        border-size = 3;
        border-radius = 12;
        default-timeout = 5000;
        font = "JetBrainsMono Nerd Font 11";
        width = 350;
        height = 150;
        margin = "16";
        padding = "12";
      };
    };

    home.packages = with pkgs; [
      kitty
      pavucontrol
      networkmanagerapplet
    ];

    programs.kitty = {
      enable = true;
      settings = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 14;

        background = "#191724";
        foreground = "#e0def4";
        cursor = "#ebbcba";
        cursor_text_color = "#191724";
        selection_background = "#403d52";
        selection_foreground = "#e0def4";

        active_tab_background = "#c4a7e7";
        active_tab_foreground = "#191724";
        inactive_tab_background = "#26233a";
        inactive_tab_foreground = "#6e6a86";

        color0 = "#26233a";
        color1 = "#eb6f92";
        color2 = "#31748f";
        color3 = "#f6c177";
        color4 = "#9ccfd8";
        color5 = "#c4a7e7";
        color6 = "#ebbcba";
        color7 = "#e0def4";

        color8 = "#6e6a86";
        color9 = "#eb6f92";
        color10 = "#31748f";
        color11 = "#f6c177";
        color12 = "#9ccfd8";
        color13 = "#c4a7e7";
        color14 = "#ebbcba";
        color15 = "#e0def4";

        background_opacity = "0.80";
        dynamic_background_opacity = "yes";
        background_blur = 1;
        window_padding_width = 12;
        confirm_os_window_close = 0;

        enable_audio_bell = false;
        shell_integration = "enabled";
      };
      keybindings = {
        "shift+enter" = "send_text all \\x1b[13;2u";
      };
    };

    home.file.".config/swayosd/style.css".text = ''
      window {
        background: rgba(31, 29, 46, 0.95);
        border-radius: 20px;
        border: 2px solid rgba(196, 167, 231, 0.4);
        padding: 12px 20px;
      }

      #container {
        margin: 16px;
      }

      image {
        margin-right: 12px;
        color: #c4a7e7;
      }

      progressbar {
        min-height: 8px;
        border-radius: 4px;
        background: #26233a;
      }

      progressbar:disabled {
        background: #403d52;
      }

      progressbar progress {
        min-height: 8px;
        border-radius: 4px;
        background: linear-gradient(90deg, #c4a7e7, #ebbcba);
      }

      label {
        color: #e0def4;
        font-family: "Quicksand", sans-serif;
        font-weight: 600;
        font-size: 14px;
      }
    '';
  };
}
