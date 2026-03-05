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
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ./hardware.nix
    ./disk-config.nix
    ../../../profiles/server.nix
    ../../../modules/nixos/sops.nix
    ../../../modules/nixos/k3s
    # App services - keep running on NixOS, ingress via k8s
    ./services/personal-website.nix
    ./services/rkm-backend.nix
    ./services/rkm-frontend.nix
    ./services/rkm-admin-frontend.nix
    ./services/roasting-startup.nix
    # ./services/rag-server.nix  # Temporarily disabled
    # ./services/nix-pilot.nix  # Disabled - needs recursion_limit fix
    ./services/verychic-frontend.nix
    ./services/kilat.nix
    # Keep backup and data services
    ./services/backup.nix
    ./services/yes-date-me-backup.nix
    ./services/minio.nix
  ];

  # Disable NixOS nginx external ports - nginx-ingress in k8s handles 80/443
  # NixOS nginx still runs for internal static file serving
  services.nginx = {
    enable = true;
    defaultHTTPListenPort = 8080;  # Internal port for static sites
    defaultSSLListenPort = 8443;   # Not used but required
    recommendedProxySettings = true;
    recommendedOptimisation = true;
  };

  # Disable ACME for NixOS nginx (cert-manager handles SSL now)
  security.acme.acceptTerms = lib.mkForce true;
  security.acme.defaults.email = lib.mkForce "maulanasdqn@gmail.com";

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2GB
    }
  ];

  # Ensure PostgreSQL database exists for kilat user (ensureDBOwnership requirement)
  services.postgresql.ensureDatabases = [ "kilat" ];

  # Enable k3s Kubernetes cluster
  services.k3s = {
    enable = true;
    role = "server";
  };

  # Create stable symlinks for k8s nginx to serve static frontends
  # These paths don't change on rebuild, only the symlink targets do
  systemd.tmpfiles.rules = [
    "L+ /var/www/rkm-frontend - - - - ${rkm-frontend.packages.${system}.default}/share/rkm-frontend"
    "L+ /var/www/rkm-admin-frontend - - - - ${rkm-admin-frontend.packages.${system}.default}"
    "L+ /var/www/verychic-frontend - - - - ${verychic-frontend.packages.${system}.default}/share/verychic-frontend"
    "L+ /var/www/kilat-ui - - - - ${kilat-app.packages.${system}.kilat-ui}"
  ];

  # Auto-restart k8s frontend pods after NixOS rebuild to pick up new symlink targets
  systemd.services.k8s-frontend-reload = {
    description = "Reload k8s frontend deployments after NixOS activation";
    wantedBy = [ "multi-user.target" ];
    after = [ "k3s.service" "systemd-tmpfiles-resetup.service" ];
    requires = [ "k3s.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    # Store hash of symlink targets to detect changes
    script = ''
      HASH_FILE="/var/lib/k8s-frontend-reload/symlinks.hash"
      mkdir -p /var/lib/k8s-frontend-reload

      # Calculate hash of current symlink targets
      CURRENT_HASH=$(readlink /var/www/rkm-frontend /var/www/verychic-frontend /var/www/kilat-ui 2>/dev/null | sha256sum | cut -d' ' -f1)

      # Check if hash changed
      if [ -f "$HASH_FILE" ]; then
        OLD_HASH=$(cat "$HASH_FILE")
        if [ "$CURRENT_HASH" != "$OLD_HASH" ]; then
          echo "Symlinks changed, restarting frontend pods..."
          /run/current-system/sw/bin/kubectl rollout restart deployment rkm-frontend verychic-frontend -n apps 2>/dev/null || true
        fi
      fi

      # Save current hash
      echo "$CURRENT_HASH" > "$HASH_FILE"
    '';
  };

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
