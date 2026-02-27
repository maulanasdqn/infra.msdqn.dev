{
  config,
  lib,
  pkgs,
  username,
  enableTilingWM,
  hostname ? "nixos",
  ...
}:
let
  # Ambil swap device pertama secara otomatis dari swapDevices
  swapDevices = config.swapDevices;
  hasSwap = swapDevices != [ ];
  firstSwap = if hasSwap then (builtins.head swapDevices) else null;
  resumeDevice = if firstSwap != null then firstSwap.device else null;
in
{
  imports = [
    ./base.nix
    ../modules/nixos/printing.nix
  ];

  # Hibernate configuration - otomatis dari swapDevices
  boot.resumeDevice = lib.mkIf (resumeDevice != null) resumeDevice;

  systemd.sleep.extraConfig = lib.mkIf (resumeDevice != null) ''
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    HibernateDelaySec=1h
  '';

  users.groups.plugdev = { };

  users.users.${username}.extraGroups = [
    "wheel"
    "networkmanager"
    "docker"
    "audio"
    "video"
    "dialout"
    "plugdev"
    "lp"
  ];


  networking.networkmanager.enable = true;

  networking.firewall.enable = true;

  networking.hostName = hostname;

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
    firefox.enable = false;
    git = {
      enable = true;
      lfs.enable = true;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # Printing - CUPS with support for SMARTCOM BT-801 thermal printer 80mm
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters        # Generic filters + support for raw/ESC-POS printers
      gutenprint          # Additional printer drivers
      gutenprintBin       # Binary gutenprint drivers
    ];
    browsing = true;
    defaultShared = false;
    # Allow raw printing for ESC/POS thermal printers
    extraConf = ''
      FileDevice Yes
      DefaultAuthType Basic
    '';
  };
  # Avahi for network printer discovery (optional, useful if printer is networked)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # RFCOMM bind untuk SMARTCOM BT-801 thermal printer (RPP02N)
  # MAC Address: 86:67:7A:CE:07:41, Channel: 1
  systemd.services.rfcomm-printer = {
    description = "Bind RFCOMM0 to SMARTCOM BT-801 Bluetooth Thermal Printer";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bluez}/bin/rfcomm bind 0 86:67:7A:CE:07:41 1";
      ExecStop = "${pkgs.bluez}/bin/rfcomm release 0";
    };
  };

  # Udev rule untuk set permission /dev/rfcomm0 agar bisa diakses CUPS
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="16c0", ATTR{idProduct}=="05dc", GROUP="plugdev", MODE="0666"
    KERNEL=="rfcomm[0-9]*", MODE="0666", GROUP="lp"
  '';

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
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "suspend";  # Ketika di-charge, suspend saja
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
      usbutils
      htop
      btop
      neofetch
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
