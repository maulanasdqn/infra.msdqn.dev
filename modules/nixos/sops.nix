{
  config,
  secretsFile,
  pkgs,
  ...
}:
{

  system.activationScripts.sshDir = ''
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
  '';

  programs.ssh.knownHosts = {
    "github.com".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };

  sops = {
    defaultSopsFile = secretsFile;

    age = {

      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {

      "personal_website_env" = {
        mode = "0400";
        owner = "root";
      };

      "rclone_config" = {
        mode = "0400";
        owner = "root";
      };

      "ssh_private_key" = {
        mode = "0600";
        owner = "root";
        path = "/root/.ssh/id_ed25519";
      };

      "kilat_env" = {
        mode = "0400";
        owner = "root";
      };

      "minio_env" = {
        mode = "0400";
        owner = "root";
      };

      "warehouse_env" = {
        mode = "0400";
        owner = "root";
      };
    };
  };
}
