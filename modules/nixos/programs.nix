{
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

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

  programs = {
    firefox.enable = true;

    git = {
      enable = true;
      lfs.enable = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    unzip
    zip
    htop
    btop
    fastfetch

    gcc
    gnumake
    cmake

    gnome-tweaks
    dconf-editor
  ];

  services.printing.enable = true;

  system.stateVersion = "25.05";
}
