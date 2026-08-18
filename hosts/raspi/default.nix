{
  lib,
  pkgs,
  sshKeys,
  ...
}:
{
  imports = [
    ./hardware.nix
    ../../profiles/base.nix
    ../../modules/nixos/adguard
  ];

  services.resolved.enable = false;

  networking = {
    hostName = "raspi";
    useDHCP = false;
    nameservers = [ "127.0.0.1" ];
    defaultGateway = {
      address = "192.168.100.1";
      interface = "end0";
    };
    interfaces.end0 = {
      ipv4.addresses = [
        {
          address = "192.168.100.139";
          prefixLength = 24;
        }
      ];
    };

    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        22
        53
        80
        443
        3000
        8082
      ];
      allowedUDPPorts = [
        53
      ];
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      MaxAuthTries = 3;
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "168h";
      multipliers = "1 2 4 8 16 32 64";
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "04:00";
  };

  services.logrotate.enable = true;

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "fs.file-max" = 131072;
    "net.core.rmem_max" = 8388608;
    "net.core.wmem_max" = 8388608;
    "net.core.netdev_max_backlog" = 5000;
  };

  nix.settings = {
    max-jobs = 2;
    cores = 2;
    substituters = [
      "https://cache.nixos.org"
      "https://msdqn.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "msdqn.cachix.org-1:I5z8egjNf2iKYLwLGF2REfpELlFoUdaSLsh7dQk1a+o="
    ];
  };

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "raspi.local:8082,192.168.100.139:8082";
    settings = {
      title = "msdqn homelab";
      favicon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/heimdall.png";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      layout = {
        Network = {
          style = "row";
          columns = 3;
        };
        Servers = {
          style = "row";
          columns = 3;
        };
        CCTV = {
          style = "row";
          columns = 2;
        };
        Cloud = {
          style = "row";
          columns = 2;
        };
      };
    };
    services = [
      {
        Network = [
          {
            "AdGuard Home" = {
              icon = "adguard-home";
              href = "http://raspi.local:3000";
              description = "DNS Ad Blocker";
              server = "raspi";
              container = "adguard";
              widget = {
                type = "adguard";
                url = "http://127.0.0.1:3000";
              };
            };
          }
          {
            "Ruijie Router" = {
              icon = "router";
              href = "http://192.168.100.1";
              description = "Huawei ONT Gateway";
            };
          }
        ];
      }
      {
        Servers = [
          {
            "Raspberry Pi" = {
              icon = "raspberry-pi";
              href = "http://raspi.local:8082";
              description = "NixOS — DNS + Dashboard";
            };
          }
          {
            "Vivobook" = {
              icon = "proxmox";
              href = "http://192.168.100.200:8080";
              description = "NixOS — CCTV + Home Server";
            };
          }
          {
            "Hostinger VPS" = {
              icon = "vps";
              href = "http://72.62.125.38";
              description = "msdqn.dev";
            };
          }
        ];
      }
      {
        CCTV = [
          {
            "Webcam Vivobook" = {
              icon = "frigate";
              href = "http://192.168.100.200:8081";
              description = "Motion CCTV — 720p Live Stream";
            };
          }
          {
            "Xiaomi C302N" = {
              icon = "frigate";
              href = "http://192.168.100.119";
              description = "192.168.100.119 — Enable RTSP via Mi Home app";
            };
          }
        ];
      }
    ];
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        search = {
          provider = "google";
          target = "_blank";
        };
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    htop
    iotop
    tmux
    jq
    dnsutils
    tcpdump
    libraspberrypi
  ];
}
