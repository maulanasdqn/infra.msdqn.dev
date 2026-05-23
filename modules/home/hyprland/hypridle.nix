{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
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
            timeout = 300;                                   # 5 min — lock
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 420;                                   # 7 min — screen off
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 900;                                   # 15 min — suspend
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
