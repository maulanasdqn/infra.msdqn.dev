{
  pkgs,
  username,
  ...
}:
let
  # Caffeine toggle — flip a "never lock/sleep" mode on or off.
  # hypridle is the only thing that drives auto lock / dpms-off / suspend,
  # so stopping it = screen never locks or sleeps on idle. Manual $mod+X
  # (hyprlock) and the lid switch still work.
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
