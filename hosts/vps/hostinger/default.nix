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

    ./services/kya-field-quote.nix
    ./services/kya-sales-reporting.nix
    ./services/kya-bond-closeout.nix
    ./services/kya-bill-pay.nix
    ./services/kya-entity-license-renewal.nix
    ./services/kya-field-checklist.nix
    ./services/kya-bid-intake.nix
    ./services/kya-ci-runner-env.nix
  ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

  };

  security.acme = {
    acceptTerms = true;
    defaults.email = acmeEmail;
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

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
  };
}
