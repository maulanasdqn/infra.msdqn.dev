{
  pkgs,
  lib,
  enableTilingWM,
  ...
}:
{
  services.xserver = {
    enable = true;

    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
    };
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Tell Chromium / Electron apps (Discord, Edge, Slack, VSCode) to run
  # natively on Wayland instead of XWayland — fixes blurry scaling and
  # GPU-process crashes on Hyprland.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  programs.hyprland = lib.mkIf enableTilingWM {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ] ++ lib.optionals enableTilingWM [
      xdg-desktop-portal-hyprland
    ];
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-music
    epiphany
    geary
    totem
  ];

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    nautilus
    libnotify
    polkit_gnome
  ] ++ lib.optionals enableTilingWM [
    hyprpaper
    hyprlock
    hypridle
    hyprpicker
    grim
    slurp
    wl-clipboard
    cliphist
    mako
  ];

  security.polkit.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.login1.suspend" ||
          action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
          action.id == "org.freedesktop.login1.hibernate" ||
          action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
      {
        return polkit.Result.YES;
      }
    });
  '';

  systemd.services.disable-usb-wake = {
    description = "Disable USB wake from suspend";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for device in XHC0 XHC1 GP17; do
        if grep -q "$device.*enabled" /proc/acpi/wakeup; then
          echo $device > /proc/acpi/wakeup
        fi
      done
    '';
  };
}
