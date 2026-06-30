{
  hostname,
  ipAddress,
  gateway,
  acmeEmail,
  lib,
  pkgs,
  rkm-frontend,
  rkm-admin-frontend,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Security headers shared across all vhosts
  securityHeaders = ''
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  '';
in
{
  imports = [
    ./hardware.nix
    ./disk-config.nix
    ../../../profiles/server.nix
    ../../../modules/nixos/sops.nix
    ./services/rkm-backend.nix
    ./services/rkm-frontend.nix
    ./services/rkm-admin-frontend.nix
    # ./services/roasting-startup.nix
    ./services/backup.nix
    ./services/yes-date-me-backup.nix
    ./services/minio.nix
    ./services/fluentbit.nix
    ./services/wazuh-agent.nix
    ./services/suricata.nix
    ./services/aysiem-heartbeat.nix
    ./services/bsm-landing.nix
    ./services/kolaborium.nix
  ];

  # NixOS nginx as the sole reverse proxy + static file server
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    # s3.rajawalikaryamulya.co.id — MinIO S3 (public media for RKM)
    virtualHosts."s3.rajawalikaryamulya.co.id" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = "client_max_body_size 1g;";
      locations."/" = {
        proxyPass = "http://127.0.0.1:9000";
      };
    };

    # rajawalikaryamulya.co.id — RKM frontend
    virtualHosts."rajawalikaryamulya.co.id" = {
      enableACME = true;
      forceSSL = true;
      serverAliases = [ "www.rajawalikaryamulya.co.id" ];
      root = "/var/www/rkm-frontend";
      extraConfig = securityHeaders;
      locations."/" = {
        tryFiles = "$uri $uri/ /index.html";
      };
      locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$" = {
        tryFiles = "$uri =404";
        extraConfig = ''
          expires 1y;
          add_header Cache-Control "public, immutable";
          ${securityHeaders}
        '';
      };
    };

    # api.rajawalikaryamulya.co.id — RKM backend
    virtualHosts."api.rajawalikaryamulya.co.id" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = securityHeaders;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3300";
      };
    };

    # cms.rajawalikaryamulya.co.id — RKM admin frontend
    virtualHosts."cms.rajawalikaryamulya.co.id" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = securityHeaders;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3100";
      };
    };

  };

  # ACME (Let's Encrypt) configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = acmeEmail;
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2GB
    }
  ];

  # Stable symlinks for static frontends — rebuild updates the target
  systemd.tmpfiles.rules = [
    "L+ /var/www/rkm-frontend - - - - ${rkm-frontend.packages.${system}.default}/share/rkm-frontend"
    "L+ /var/www/rkm-admin-frontend - - - - ${rkm-admin-frontend.packages.${system}.default}"
  ];

  # Open HTTP/HTTPS for nginx
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  networking = {
    hostName = hostname;
    useDHCP = false;
    interfaces.ens18.ipv4.addresses = [
      {
        address = ipAddress;
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = gateway;
      interface = "ens18";
    };
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];
    extraHosts = ''
      103.31.205.209 ingest-aysiem.msdqn.dev
    '';
  };
}
