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

        monitor = ",preferred,auto,1.25";

        exec-once = [
          "hyprctl setcursor Bibata-Modern-Classic 24"
          "hyprpaper"
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
          pseudotile = true;
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
          sensitivity = 0.5;
          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
          };
        };

        cursor = {
          default_monitor = "";
        };

        env = [
          "XCURSOR_THEME,Bibata-Modern-Classic"
          "XCURSOR_SIZE,24"
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
          "$mod, P, pseudo"
          "$mod, J, togglesplit"

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

    home.file.".config/hypr/hyprpaper.conf".text = ''
      preload = ~/Downloads/2109.jpg
      wallpaper = ,~/Downloads/2109.jpg
      splash = false
    '';

    home.file.".config/hypr/hyprlock.conf".text = ''
      background {
        monitor =
        path = ~/Downloads/2109.jpg
        blur_passes = 3
        blur_size = 8
        brightness = 1.0
      }

      input-field {
        monitor =
        size = 300, 50
        outline_thickness = 3
        dots_size = 0.33
        dots_spacing = 0.15
        dots_center = true
        outer_color = rgb(c4a7e7)
        inner_color = rgb(1f1d2e)
        font_color = rgb(e0def4)
        fade_on_empty = false
        placeholder_text = <span foreground="##c4a7e7">Password...</span>
        hide_input = false
        position = 0, -20
        halign = center
        valign = center
      }

      label {
        monitor =
        text = Hi Cutie!
        color = rgb(c4a7e7)
        font_size = 48
        font_family = JetBrainsMono Nerd Font
        position = 0, 150
        halign = center
        valign = center
      }

      label {
        monitor =
        text = $TIME
        color = rgb(e0def4)
        font_size = 96
        font_family = JetBrainsMono Nerd Font
        position = 0, 50
        halign = center
        valign = center
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
