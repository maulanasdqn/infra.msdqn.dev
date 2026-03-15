{
  hostname,
  ipAddress,
  gateway,
  acmeEmail,
  lib,
  pkgs,
  rkm-frontend,
  rkm-admin-frontend,
  verychic-frontend,
  kilat-app,
  warehouse-management,
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
    ./services/personal-website.nix
    ./services/rkm-backend.nix
    ./services/rkm-frontend.nix
    ./services/rkm-admin-frontend.nix
    ./services/roasting-startup.nix
    ./services/verychic-frontend.nix
    ./services/kilat.nix
    ./services/warehouse-management.nix
    ./services/backup.nix
    ./services/yes-date-me-backup.nix
    ./services/minio.nix
    ./services/fluentbit.nix
    ./services/wazuh-agent.nix
    ./services/aysiem-heartbeat.nix
  ];

  # NixOS nginx as the sole reverse proxy + static file server
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    # Rate limiting zones are defined by the kilat-app NixOS module
    # (api_limit, auth_limit, static_limit, ai_limit, upload_limit, conn_per_ip)

    # kilat.app — frontend static files
    virtualHosts."kilat.app" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www/kilat-ui";
      extraConfig = ''
        limit_conn conn_per_ip 20;
        ${securityHeaders}
      '';
      locations."/" = {
        tryFiles = "$uri $uri/ /index.html";
        extraConfig = "limit_req zone=static_limit burst=20 nodelay;";
      };
      locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$" = {
        tryFiles = "$uri =404";
        extraConfig = ''
          limit_req zone=static_limit burst=100 nodelay;
          expires 1y;
          add_header Cache-Control "public, immutable";
          ${securityHeaders}
        '';
      };
    };

    # api.kilat.app — backend API
    virtualHosts."api.kilat.app" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 100m;
        ${securityHeaders}
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:8082";
        extraConfig = "limit_req zone=api_limit burst=30 nodelay;";
      };
    };

    # storage.kilat.app + s3.msdqn.dev — MinIO S3
    virtualHosts."storage.kilat.app" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = "client_max_body_size 1g;";
      locations."/" = {
        proxyPass = "http://127.0.0.1:9000";
      };
    };

    # s3.msdqn.dev needs its own cert since it's a different domain
    virtualHosts."s3.msdqn.dev" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = "client_max_body_size 1g;";
      locations."/" = {
        proxyPass = "http://127.0.0.1:9000";
      };
    };

    # api-warehouse.msdqn.dev — Warehouse Management API
    virtualHosts."api-warehouse.msdqn.dev" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = securityHeaders;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8090";
      };
    };

    # warehouse.msdqn.dev — Warehouse Management Frontend
    virtualHosts."warehouse.msdqn.dev" = {
      enableACME = true;
      forceSSL = true;
      root = "${warehouse-management.packages.${system}.wm-web}";
      extraConfig = securityHeaders;
      locations."/" = {
        tryFiles = "$uri $uri/ /index.html";
      };
      locations."~* \\.(js|css|woff|woff2)$" = {
        tryFiles = "$uri =404";
        extraConfig = ''
          expires 1y;
          add_header Cache-Control "public, immutable";
          ${securityHeaders}
        '';
      };
    };

    # msdqn.dev — personal website
    virtualHosts."msdqn.dev" = {
      enableACME = true;
      forceSSL = true;
      serverAliases = [ "www.msdqn.dev" ];
      extraConfig = securityHeaders;
      locations."/" = {
        proxyPass = "http://127.0.0.1:4321";
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

    # roast.kilat.app — Roasting Startup
    virtualHosts."roast.kilat.app" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = securityHeaders;
      locations."/" = {
        proxyPass = "http://127.0.0.1:7676";
      };
    };

    # verychic.msdqn.dev — Verychic frontend
    virtualHosts."verychic.msdqn.dev" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www/verychic-frontend";
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

  services.postgresql.ensureDatabases = [ "kilat" ];

  # Stable symlinks for static frontends — rebuild updates the target
  systemd.tmpfiles.rules = [
    "L+ /var/www/rkm-frontend - - - - ${rkm-frontend.packages.${system}.default}/share/rkm-frontend"
    "L+ /var/www/rkm-admin-frontend - - - - ${rkm-admin-frontend.packages.${system}.default}"
    "L+ /var/www/verychic-frontend - - - - ${verychic-frontend.packages.${system}.default}/share/verychic-frontend"
    "L+ /var/www/kilat-ui - - - - ${kilat-app.packages.${system}.kilat-ui}"
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
  };
}
