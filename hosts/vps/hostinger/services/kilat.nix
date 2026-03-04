{ config, pkgs, acmeEmail, kilat-app, ... }:
{
  # Set password for kilat PostgreSQL user after service starts
  systemd.services.postgresql.postStart = pkgs.lib.mkAfter ''
    $PSQL -c "ALTER USER kilat WITH PASSWORD 'kilat';" || true
  '';

  services.kilat = {
    enable = true;
    port = 8082;
    host = "0.0.0.0";  # Bind to all interfaces for k8s access
    databaseUrl = "postgresql://kilat:kilat@localhost:5432/kilat_app";
    environmentFile = config.sops.secrets.kilat_env.path;

    # MinIO disabled - using existing MinIO service
    minio.enable = false;

    # nginx handled by k8s nginx-ingress
    nginx.enable = false;
  };

  # Ensure kilat services start after sops secrets and MinIO
  systemd.services.kilat-server = {
    after = [ "sops-nix.service" "minio.service" ];
    wants = [ "sops-nix.service" "minio.service" ];
    serviceConfig.EnvironmentFile = [
      config.sops.secrets.minio_env.path
    ];
    environment = {
      MINIO_ENDPOINT = "http://127.0.0.1:9000";
      MINIO_BUCKET = "kilat-media";
      MINIO_REGION = "us-east-1";
      MINIO_PUBLIC_URL = "https://storage.kilat.app/kilat-media";
    };
  };

  systemd.services.kilat-migration = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  # Create kilat-media bucket in MinIO
  systemd.services.kilat-minio-init = {
    description = "Initialize Kilat MinIO bucket";
    wantedBy = [ "multi-user.target" ];
    after = [ "minio.service" "sops-nix.service" ];
    requires = [ "minio.service" ];
    wants = [ "sops-nix.service" ];
    before = [ "kilat-server.service" ];

    path = [ pkgs.minio-client pkgs.glibc pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      export HOME="/tmp/mc-home"
      mkdir -p $HOME

      # Source MinIO credentials from sops
      source ${config.sops.secrets.minio_env.path}

      for i in {1..30}; do
        if ${pkgs.minio-client}/bin/mc alias set local http://127.0.0.1:9000 "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" 2>/dev/null; then
          break
        fi
        echo "Waiting for MinIO... ($i/30)"
        sleep 2
      done

      ${pkgs.minio-client}/bin/mc mb --ignore-existing local/kilat-media
      ${pkgs.minio-client}/bin/mc anonymous set download local/kilat-media
      echo "MinIO bucket 'kilat-media' ready"
    '';
  };

  # Serve kilat-ui frontend via NixOS nginx (k8s ingress proxies to port 8080)
  services.nginx.virtualHosts."kilat.app" = {
    listen = [{ addr = "0.0.0.0"; port = 8080; }];
    root = kilat-app.packages.${pkgs.stdenv.hostPlatform.system}.kilat-ui;
    locations."/" = {
      tryFiles = "$uri $uri/ /index.html";
    };
  };
}
