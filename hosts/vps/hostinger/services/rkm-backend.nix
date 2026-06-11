{ config, acmeEmail, ... }:
{
  services.rkm-backend = {
    enable = true;
    port = 3300;
    host = "127.0.0.1";
    databaseUrl = "postgresql://rkm:rkm@localhost:5432/rkm";
    environmentFile = config.sops.secrets.rkm_backend_env.path;
    nginx.enable = false;
  };

  systemd.services.rkm-backend = {
    after = [ "sops-nix.service" "minio.service" ];
    wants = [ "sops-nix.service" "minio.service" ];
    serviceConfig.EnvironmentFile = [
      config.sops.secrets.minio_env.path
    ];
    environment = {
      MINIO_ENDPOINT = "http://127.0.0.1:9000";
      MINIO_BUCKET = "rkm-media";
      MINIO_REGION = "us-east-1";
      MINIO_PUBLIC_URL = "https://s3.rajawalikaryamulya.co.id/rkm-media";
    };
  };
}
