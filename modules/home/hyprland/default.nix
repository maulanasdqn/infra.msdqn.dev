{
  lib,
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
      configType = "lua";

      settings =
        let
          inherit (lib.generators) mkLuaInline;

          key = k: mkLuaInline ''mod .. " + ${k}"'';
          shiftKey = k: mkLuaInline ''mod .. " + SHIFT + ${k}"'';
          dsp = expr: mkLuaInline expr;
          run = cmd: mkLuaInline ''hl.dsp.exec_cmd([[${cmd}]])'';

          workspaceBinds = lib.concatMap (
            i:
            let
              k = if i == 10 then "0" else toString i;
            in
            [
              {
                _args = [
                  (key k)
                  (dsp "hl.dsp.focus({ workspace = ${toString i} })")
                ];
              }
              {
                _args = [
                  (shiftKey k)
                  (dsp "hl.dsp.window.move({ workspace = ${toString i} })")
                ];
              }
            ]
          ) (lib.range 1 10);

          opacityRule = class: active: inactive: {
            name = "opacity-${class}";
            match.class = "^(${class})$";
            opacity = "${active} ${inactive}";
          };

          floatRule = name: matchAttrs: {
            name = "float-${name}";
            match = matchAttrs;
            float = true;
          };

          blurLayer = namespace: {
            name = "blur-${namespace}";
            match.namespace = namespace;
            blur = true;
            ignore_alpha = 0.3;
          };
        in
        {
          mod = {
            _var = "ALT";
          };
          terminal = {
            _var = "kitty";
          };
          menu = {
            _var = "wofi --show drun";
          };
          browser = {
            _var = "helium-browser";
          };
          fileManager = {
            _var = "nautilus";
          };

          monitor = [
            {
              output = "eDP-1";
              mode = "2880x1800@90";
              position = "0x0";
              scale = 1.5;
            }
            {
              output = "HDMI-A-1";
              mode = "1920x1080@60";
              position = "auto";
              scale = 0.8;
            }
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1.0;
            }
          ];

          env = [
            { _args = [ "XCURSOR_THEME" "macOS" ]; }
            { _args = [ "XCURSOR_SIZE" "40" ]; }
            { _args = [ "NIXOS_OZONE_WL" "1" ]; }
            { _args = [ "ELECTRON_OZONE_PLATFORM_HINT" "auto" ]; }
            { _args = [ "MOZ_ENABLE_WAYLAND" "1" ]; }
          ];

          on = {
            _args = [
              "hyprland.start"
              (mkLuaInline ''
                function()
                    hl.exec_cmd([[hyprlock --immediate]])
                    hl.exec_cmd([[hyprctl setcursor macOS 40]])
                    hl.exec_cmd([[swaybg -c 000000]])
                    hl.exec_cmd([[eww open bar]])
                    hl.exec_cmd([[swayosd-server]])
                    hl.exec_cmd([[${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1]])
                    hl.exec_cmd([[wl-paste --type text --watch cliphist store]])
                    hl.exec_cmd([[wl-paste --type image --watch cliphist store]])
                end'')
            ];
          };

          config = {
            general = {
              gaps_in = 8;
              gaps_out = 16;
              border_size = 1;
              col = {
                active_border = mkLuaInline ''{ colors = { "rgb(c4a7e7)", "rgb(ebbcba)" }, angle = 45 }'';
                inactive_border = "rgb(403d52)";
              };
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

            animations.enabled = true;

            dwindle = {
              preserve_split = true;
              force_split = 2;
            };

            master.new_status = "master";

            input = {
              kb_layout = "us";
              kb_options = "caps:escape";
              follow_mouse = 1;
              sensitivity = 0.0;
              accel_profile = "adaptive";
              scroll_factor = 1.0;
              touchpad = {
                natural_scroll = true;
                tap_to_click = true;
                scroll_factor = 0.2;
              };
            };

            cursor.default_monitor = "";

            misc = {
              force_default_wallpaper = 0;
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
            };
          };

          curve = [
            { _args = [ "cute" (mkLuaInline ''{ type = "bezier", points = { { 0.68, -0.55 }, { 0.265, 1.55 } } }'') ]; }
            { _args = [ "smooth" (mkLuaInline ''{ type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1 } } }'') ]; }
            { _args = [ "bounce" (mkLuaInline ''{ type = "bezier", points = { { 0.68, -0.6 }, { 0.32, 1.6 } } }'') ]; }
            { _args = [ "fadeBounce" (mkLuaInline ''{ type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } }'') ]; }
          ];

          animation = [
            { leaf = "windows"; enabled = true; speed = 5; bezier = "bounce"; style = "slide"; }
            { leaf = "windowsOut"; enabled = true; speed = 5; bezier = "cute"; style = "slide"; }
            { leaf = "border"; enabled = true; speed = 10; bezier = "smooth"; }
            { leaf = "borderangle"; enabled = true; speed = 100; bezier = "smooth"; style = "loop"; }
            { leaf = "fade"; enabled = true; speed = 5; bezier = "smooth"; }
            { leaf = "workspaces"; enabled = true; speed = 5; bezier = "smooth"; style = "slidefade 20%"; }
          ];

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

          gesture = [
            {
              fingers = 3;
              direction = "horizontal";
              action = "workspace";
            }
          ];

          window_rule = [
            (floatRule "pavucontrol" { class = "^(pavucontrol)$"; })
            (floatRule "nm-connection-editor" { class = "^(nm-connection-editor)$"; })
            (floatRule "calculator" { class = "^(org.gnome.Calculator)$"; })
            (floatRule "picture-in-picture" { title = "^(Picture-in-Picture)$"; })
            (opacityRule "kitty" "1.0" "0.92")
            (opacityRule "Alacritty" "1.0" "0.92")
            (opacityRule "code" "0.9" "0.9")
          ];

          layer_rule = [
            (blurLayer "gtk-layer-shell")
            (blurLayer "wofi")
          ];

          bind =
            [
              { _args = [ (key "Return") (dsp "hl.dsp.exec_cmd(terminal)") ]; }
              { _args = [ (key "Space") (dsp "hl.dsp.exec_cmd(menu)") ]; }
              { _args = [ (key "D") (dsp "hl.dsp.exec_cmd(menu)") ]; }
              { _args = [ (key "E") (dsp "hl.dsp.exec_cmd(fileManager)") ]; }
              { _args = [ (key "B") (dsp "hl.dsp.exec_cmd(browser)") ]; }

              { _args = [ (shiftKey "Q") (dsp "hl.dsp.window.close()") ]; }
              { _args = [ (shiftKey "E") (dsp "hl.dsp.exit()") ]; }
              { _args = [ (key "V") (dsp ''hl.dsp.window.float({ action = "toggle" })'') ]; }
              { _args = [ (key "F") (dsp "hl.dsp.window.fullscreen()") ]; }
              { _args = [ (shiftKey "B") (run "eww open --toggle bar") ]; }
              { _args = [ (shiftKey "T") (run "fix-touchpad") ]; }
              { _args = [ (shiftKey "H") (run "systemctl hibernate") ]; }

              { _args = [ (key "left") (dsp ''hl.dsp.focus({ direction = "left" })'') ]; }
              { _args = [ (key "right") (dsp ''hl.dsp.focus({ direction = "right" })'') ]; }
              { _args = [ (key "up") (dsp ''hl.dsp.focus({ direction = "up" })'') ]; }
              { _args = [ (key "down") (dsp ''hl.dsp.focus({ direction = "down" })'') ]; }
              { _args = [ (key "H") (dsp ''hl.dsp.focus({ direction = "left" })'') ]; }
              { _args = [ (key "L") (dsp ''hl.dsp.focus({ direction = "right" })'') ]; }
              { _args = [ (key "K") (dsp ''hl.dsp.focus({ direction = "up" })'') ]; }
              { _args = [ (key "J") (dsp ''hl.dsp.focus({ direction = "down" })'') ]; }

              { _args = [ (key "S") (dsp ''hl.dsp.workspace.toggle_special("magic")'') ]; }
              { _args = [ (shiftKey "S") (dsp ''hl.dsp.window.move({ workspace = "special:magic" })'') ]; }

              { _args = [ (key "mouse_down") (dsp ''hl.dsp.focus({ workspace = "e+1" })'') ]; }
              { _args = [ (key "mouse_up") (dsp ''hl.dsp.focus({ workspace = "e-1" })'') ]; }

              { _args = [ "Print" (run ''grim -g "$(slurp)" - | wl-copy'') ]; }
              { _args = [ "SHIFT + Print" (run "grim - | wl-copy") ]; }

              { _args = [ (key "C") (run "cliphist list | wofi --dmenu | cliphist decode | wl-copy") ]; }
              { _args = [ (shiftKey "C") (run "hyprpicker -a") ]; }

              { _args = [ (key "X") (run "hyprlock") ]; }
              { _args = [ (shiftKey "X") (run "caffeine") ]; }

              {
                _args = [
                  (key "mouse:272")
                  (dsp "hl.dsp.window.drag()")
                  { mouse = true; }
                ];
              }
              {
                _args = [
                  (key "mouse:273")
                  (dsp "hl.dsp.window.resize()")
                  { mouse = true; }
                ];
              }

              {
                _args = [
                  "XF86AudioRaiseVolume"
                  (run "swayosd-client --output-volume +2")
                  {
                    locked = true;
                    repeating = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioLowerVolume"
                  (run "swayosd-client --output-volume -2")
                  {
                    locked = true;
                    repeating = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioMute"
                  (run "swayosd-client --output-volume mute-toggle")
                  { locked = true; }
                ];
              }
              {
                _args = [
                  "XF86AudioMicMute"
                  (run "swayosd-client --input-volume mute-toggle")
                  { locked = true; }
                ];
              }
              {
                _args = [
                  "switch:on:Lid Switch"
                  (run "systemctl suspend")
                  { locked = true; }
                ];
              }
              {
                _args = [
                  "XF86MonBrightnessUp"
                  (run "swayosd-client --brightness +2")
                  { repeating = true; }
                ];
              }
              {
                _args = [
                  "XF86MonBrightnessDown"
                  (run "swayosd-client --brightness -2")
                  { repeating = true; }
                ];
              }
            ]
            ++ workspaceBinds;
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
        color = rgba(000000ff)
        blur_passes = 0
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
