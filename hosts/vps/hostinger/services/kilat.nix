{ config, pkgs, acmeEmail, ... }:
{
  # Set password for kilat PostgreSQL user after service starts
  systemd.services.postgresql.postStart = pkgs.lib.mkAfter ''
    $PSQL -c "ALTER USER kilat WITH PASSWORD 'kilat';" || true
  '';

  services.kilat = {
    enable = true;
    port = 8082;
    host = "127.0.0.1";
    databaseUrl = "postgresql://kilat:kilat@localhost:5432/kilat_app";
    environmentFile = config.sops.secrets.kilat_env.path;

    # MinIO disabled - using existing MinIO service
    minio.enable = false;

    nginx = {
      enable = true;
      domain = "kilat.app";
      apiDomain = "api.kilat.app";
      storageDomain = "storage.kilat.app";
      enableSSL = true;
      acmeEmail = acmeEmail;
    };
  };

  # Ensure kilat services start after sops secrets and MinIO
  systemd.services.kilat-server = {
    after = [ "sops-nix.service" "minio.service" ];
    wants = [ "sops-nix.service" "minio.service" ];
    environment = {
      MINIO_ENDPOINT = "http://127.0.0.1:9000";
      MINIO_ACCESS_KEY = "minioadmin";
      MINIO_SECRET_KEY = "MinioSecure2026!";
      MINIO_BUCKET = "kilat-media";
      MINIO_REGION = "us-east-1";
      MINIO_PUBLIC_URL = "https://s3.msdqn.dev/kilat-media";
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
    after = [ "minio.service" ];
    requires = [ "minio.service" ];
    before = [ "kilat-server.service" ];

    path = [ pkgs.minio-client pkgs.glibc.bin ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      DynamicUser = true;
    };

    script = ''
      for i in {1..30}; do
        if mc alias set local http://127.0.0.1:9000 minioadmin "MinioSecure2026!" 2>/dev/null; then
          break
        fi
        echo "Waiting for MinIO... ($i/30)"
        sleep 2
      done

      mc mb --ignore-existing local/kilat-media
      mc anonymous set download local/kilat-media
      echo "MinIO bucket 'kilat-media' ready"
    '';
  };
}
