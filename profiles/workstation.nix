{
  lib,
  pkgs,
  username,
  enableTilingWM,
  ...
}:
{
  imports = [
    ./base.nix
  ];

  users.users.${username}.extraGroups = [
    "wheel"
    "networkmanager"
    "docker"
    "audio"
    "video"
  ];

  networking.networkmanager.enable = true;

  networking.firewall.enable = true;

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

  programs.hyprland = lib.mkIf enableTilingWM {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals =
      with pkgs;
      [
        xdg-desktop-portal-gtk
      ]
      ++ lib.optionals enableTilingWM [
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

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
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

  services.printing.enable = true;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  security.polkit.enable = true;

  environment.systemPackages =
    with pkgs;
    [
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
      nautilus
      libnotify
      polkit_gnome
    ]
    ++ lib.optionals enableTilingWM [
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
}
