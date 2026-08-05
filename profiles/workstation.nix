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
    ./base.nix
    ../modules/nixos/android.nix
    ../modules/nixos/performance.nix
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

  services.displayManager.regreet = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "rose-pine";
      package = pkgs.rose-pine-icon-theme;
    };
    cursorTheme = {
      name = "macOS";
      package = pkgs.apple-cursor;
    };
    font = {
      name = "Quicksand";
      package = pkgs.quicksand;
      size = 12;
    };

    settings = {
      appearance.greeting_msg = "Welcome back";
      commands = {
        reboot = [
          "systemctl"
          "reboot"
        ];
        poweroff = [
          "systemctl"
          "poweroff"
        ];
      };
    };

    extraCss = ''
      window {
        background-color: #000000;
      }

      #main-box {
        background-color: rgba(31, 29, 46, 0.88);
        border: 1px solid rgba(196, 167, 231, 0.35);
        border-radius: 16px;
        padding: 28px;
      }

      button, entry {
        border-radius: 10px;
      }
    '';
  };

  services.greetd.settings.initial_session = lib.mkIf enableTilingWM {
    command = "${config.programs.hyprland.package}/bin/Hyprland";
    user = username;
  };

  systemd.services.greetd.environment.XDG_DATA_DIRS = lib.concatStringsSep ":" [
    "${config.services.displayManager.sessionData.desktops}/share"
    "/run/current-system/sw/share"
  ];

  services.displayManager.defaultSession = lib.mkIf enableTilingWM "hyprland";

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
    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
  };

  programs.dconf.enable = true;

  security.rtkit.enable = true;

  systemd.user.services.alc256-mic-route = {
    description = "Route ALC256 capture to headset mic with sane gain";
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" "wireplumber.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
    };
    script = ''
      ${pkgs.pulseaudio}/bin/pactl set-source-port \
        alsa_input.pci-0000_03_00.6.analog-stereo \
        analog-input-headset-mic || true
      ${pkgs.pulseaudio}/bin/pactl set-source-volume \
        alsa_input.pci-0000_03_00.6.analog-stereo 50% || true
      ${pkgs.pulseaudio}/bin/pactl set-source-mute \
        alsa_input.pci-0000_03_00.6.analog-stereo 0 || true
      ${pkgs.pulseaudio}/bin/pactl set-default-source rnnoise_source || true
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Capture' 50% || true
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Headset Mic Boost' 0 || true
    '';
  };

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;

    extraLadspaPackages = [ pkgs.rnnoise-plugin ];

    extraConfig.pipewire."99-input-denoising" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Noise Canceling Source";
            "media.name" = "Noise Canceling Source";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "librnnoise_ladspa";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 50.0;
                    "VAD Grace Period (ms)" = 200;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };
            "capture.props" = {
              "node.name" = "capture.rnnoise_source";
              "node.passive" = true;
              "audio.rate" = 48000;
            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
            };
          };
        }
      ];
    };
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
    package = pkgs.docker_29;
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
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "hibernate";
    HandlePowerKeyLongPress = "poweroff";
  };

  services.udev.packages = lib.optionals enableTilingWM [ pkgs.swayosd ];

  services.udev.extraRules = ''
    # ASUP1303 touchpad firmware locks up if power-gated. Keep it fully powered.
    SUBSYSTEM=="i2c", KERNEL=="i2c-ASUP1303:00", ATTR{device/power/control}="on"
    ACTION=="add", SUBSYSTEM=="platform", KERNEL=="AMDI0010:03", ATTR{power/control}="on"
  '';

  security.sudo.extraRules = [{
    users = [ username ];
    commands = [{
      command = "/run/current-system/sw/bin/tee /sys/bus/platform/drivers/i2c_designware/unbind";
      options = [ "NOPASSWD" ];
    } {
      command = "/run/current-system/sw/bin/tee /sys/bus/platform/drivers/i2c_designware/bind";
      options = [ "NOPASSWD" ];
    }];
  }];

  systemd.services.touchpad-resume-fix = {
    description = "Reset I2C touchpad after resume";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "touchpad-resume-fix" ''
        DRV=/sys/bus/platform/drivers/i2c_designware
        DEV=AMDI0010:03
        if [ -e "$DRV/$DEV" ]; then
          echo "$DEV" > "$DRV/unbind" || true
          sleep 2
          echo "$DEV" > "$DRV/bind" || true
        fi
      '';
    };
  };

  security.polkit.enable = true;

  services.fprintd.enable = true;

  programs.hyprlock.enable = true;

  security.pam.services = {
    sudo.fprintAuth = true;
    hyprlock.fprintAuth = true;
    login.fprintAuth = true;
  };

  systemd.packages = [ pkgs.pritunl-client ];
  systemd.services.pritunl-client.wantedBy = [ "multi-user.target" ];

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
      nautilus
      libnotify
      polkit_gnome
      pritunl-client
      wireguard-tools
      (writeShellScriptBin "fix-touchpad" ''
        DRV=/sys/bus/platform/drivers/i2c_designware
        DEV=AMDI0010:03
        ${libnotify}/bin/notify-send -t 2000 "Touchpad" "Resetting controller..."
        echo "$DEV" | sudo tee "$DRV/unbind" > /dev/null 2>&1 || true
        sleep 1
        echo "$DEV" | sudo tee "$DRV/bind" > /dev/null 2>&1 || true
        sleep 2
        EV=$(grep -A6 "ASUP.*Touchpad" /proc/bus/input/devices | grep "Handlers" | grep -oE "event[0-9]+" | head -1)
        if timeout 1 dd if=/dev/input/$EV bs=24 count=1 of=/dev/null 2>/dev/null; then
          ${libnotify}/bin/notify-send -t 2000 "Touchpad" "Recovered"
        else
          ${libnotify}/bin/notify-send -u critical "Touchpad" "Reset failed - try Fn+F6 or reboot"
        fi
      '')
    ]
    ++ lib.optionals enableTilingWM [
      swaybg
      swayosd
      brightnessctl
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
