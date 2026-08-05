{
  pkgs,
  username,
  ...
}:
let

  caffeine = pkgs.writeShellScriptBin "caffeine" ''
    if ${pkgs.systemd}/bin/systemctl --user -q is-active hypridle; then
      ${pkgs.systemd}/bin/systemctl --user stop hypridle
      ${pkgs.libnotify}/bin/notify-send -t 2000 -u low \
        "☕ Caffeine ON" "Idle lock & sleep disabled"
    else
      ${pkgs.systemd}/bin/systemctl --user start hypridle
      ${pkgs.libnotify}/bin/notify-send -t 2000 -u low \
        "Caffeine OFF" "Normal idle lock & sleep restored"
    fi
  '';
in
{
  home-manager.users.${username} = {
    home.packages = [ caffeine ];

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 420;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 900;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
