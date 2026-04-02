{
  username,
  enableTilingWM,
  enableLaravel,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./packages/nixos.nix
    ./git
    ./starship
    ./zsh
    ./neovim
    ./tmux
    ./ssh
    ./vscode
    ./gnome-shortcuts.nix
  ] ++ lib.optionals enableTilingWM [
    ./hyprland
  ] ++ lib.optionals enableLaravel [
    ./laravel
  ];

  home-manager.users.${username} = {
    home = {
      username = username;
      homeDirectory = "/home/${username}";
      stateVersion = "25.05";
    };

    programs.home-manager.enable = true;

    dconf.settings = {
      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];
      };
      "org/gnome/desktop/interface" = {
        text-scaling-factor = 1.0;
        gtk-theme = "Catppuccin-Latte-Standard-Pink-Light";
        icon-theme = "Papirus-Light";
        cursor-theme = "catppuccin-mocha-pink-cursors";
        color-scheme = "prefer-light";
      };
    };

    systemd.user.services.battery-monitor = {
      Unit = {
        Description = "Low battery notification";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "battery-monitor" ''
          while true; do
            capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
            status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)

            if [ -n "$capacity" ] && [ "$status" = "Discharging" ]; then
              if [ "$capacity" -le 10 ]; then
                ${pkgs.libnotify}/bin/notify-send -u critical "Pareum ieu mah aslina!" "Tingali ieu sesa $capacity% deui. Kumadinya we lah!"
              elif [ "$capacity" -le 15 ]; then
                ${pkgs.libnotify}/bin/notify-send -u critical "Moal di Cas ieu Batre?" "Sesa $capacity% deui. Kaburu Pareum."
              elif [ "$capacity" -le 20 ]; then
                ${pkgs.libnotify}/bin/notify-send -u normal "Cas Heula ieu Batre" "Tingali $capacity% deui!"
              fi
            fi
            sleep 120
          done
        ''}";
        Restart = "always";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
