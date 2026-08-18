{
  config,
  lib,
  pkgs,
  username,
  enableTilingWM,
  ...
}:
{
  imports = [
    ./hardware.nix
    ../../../profiles/workstation.nix
  ];

  networking.hostName = "vivobook";

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = lib.mkForce "gnome";
  services.displayManager.regreet.enable = lib.mkForce false;
  services.greetd.enable = lib.mkForce false;

  security.pam.services.login.fprintAuth = lib.mkForce false;

  programs.hyprland.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    rpi-imager
    minicom
    picocom
    nmap
    libgpiod
    esptool
    espflash
    cargo-generate
    ldproxy
    openocd
    probe-rs-tools
    usbutils
    screen
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", MODE="0666"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", MODE="0666"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE="0666"
  '';

  users.users.${username}.extraGroups = [ "dialout" ];
}
