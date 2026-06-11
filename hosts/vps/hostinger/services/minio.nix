{ config, pkgs, ... }:
{
  # MinIO is abandoned upstream and flagged insecure in nixpkgs (unauthenticated
  # object-write CVEs et al). It only listens on 127.0.0.1:9000 behind the nginx
  # storage vhosts, so we knowingly keep running this pinned version until a
  # migration to a maintained S3 server (Garage/SeaweedFS) is scoped.
  nixpkgs.config.permittedInsecurePackages = [
    "minio-2025-10-15T17-29-55Z"
  ];

  services.minio = {
    enable = true;
    listenAddress = "127.0.0.1:9000";
    consoleAddress = "127.0.0.1:9001";
    dataDir = [ "/var/lib/minio/data" ];
    rootCredentialsFile = config.sops.secrets.minio_credentials.path;
  };

  systemd.services.minio = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/minio 0755 minio minio -"
    "d /var/lib/minio/data 0755 minio minio -"
  ];
}
