{
  hostname,
  ipAddress,
  gateway,
  ...
}:
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
    ./services/rag-server.nix
    # ./services/nix-pilot.nix  # Disabled - needs recursion_limit fix
    ./services/backup.nix
    ./services/yes-date-me-backup.nix
    ./services/minio.nix
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2GB
    }
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
    defaultGateway = gateway;
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];
  };
}
