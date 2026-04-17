{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../profiles/base.nix
  ];

  networking.hostName = "wsl";

  wsl = {
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;
    wslConf = {
      automount.root = "/mnt";
      interop.appendWindowsPath = false;
      network.generateHosts = true;
    };
  };

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  users.users.${username} = {
    uid = lib.mkForce 1001;
    extraGroups = [
      "wheel"
      "docker"
    ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      libgcc
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    unzip
    zip
    htop
    btop
    gcc
    gnumake
    cmake
  ];
}
