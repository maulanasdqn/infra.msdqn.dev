{
  hostname,
  ipAddress,
  gateway,
  acmeEmail,
  lib,
  pkgs,
  ...
}:
let
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
    # ./services/rkm-backend.nix  # Disabled — Rust app, excluded from clan VPS build to skip cargo compile
    # ./services/roasting-startup.nix
    ./services/backup.nix
    ./services/yes-date-me-backup.nix
    ./services/fluentbit.nix
    ./services/wazuh-agent.nix
    ./services/suricata.nix
    ./services/aysiem-heartbeat.nix
    ./services/kya-field-quote.nix
    ./services/kya-sales-reporting.nix
  ];

  # NixOS nginx as the sole reverse proxy + static file server
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    # api.rajawalikaryamulya.co.id — RKM backend (Rust)
    # Disabled — rkm-backend excluded from the VPS build (no cargo compile);
    # re-enable this vhost together with ./services/rkm-backend.nix.
    # virtualHosts."api.rajawalikaryamulya.co.id" = {
    #   enableACME = true;
    #   forceSSL = true;
    #   extraConfig = securityHeaders;
    #   locations."/" = {
    #     proxyPass = "http://127.0.0.1:3300";
    #   };
    # };

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

  # Open HTTP/HTTPS for nginx
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

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
