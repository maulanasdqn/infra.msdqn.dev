{ config, secretsFile, pkgs, ... }:
{
  # Ensure .ssh directory exists for root
  system.activationScripts.sshDir = ''
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
  '';

  # Add GitHub to known_hosts
  programs.ssh.knownHosts = {
    "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };

  sops = {
    defaultSopsFile = secretsFile;

    age = {
      # Use the server's SSH host key converted to age
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Generated age key location (will be created from SSH key)
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets = {
      # Personal website environment
      "personal_website_env" = {
        mode = "0400";
        owner = "root";
      };

      # RKM backend environment
      "rkm_backend_env" = {
        mode = "0400";
        owner = "root";
      };

      # Rclone config for backups
      "rclone_config" = {
        mode = "0400";
        owner = "root";
      };

      # SSH private key for GitHub
      "ssh_private_key" = {
        mode = "0600";
        owner = "root";
        path = "/root/.ssh/id_ed25519";
      };

      # RAG server environment (OPENAI_API_KEY)
      # "rag_server_env" = {
      #   mode = "0400";
      #   owner = "rag-server";
      # };

      # Roasting Startup environment (OPENROUTER_API_KEY) — disabled
      # "roasting_startup_env" = {
      #   mode = "0400";
      #   owner = "roasting";
      # };

      # Kilat.App environment
      "kilat_env" = {
        mode = "0400";
        owner = "root";
      };

      # MinIO credentials (root user/password)
      "minio_credentials" = {
        mode = "0400";
        owner = "minio";
      };

      # MinIO environment (access key/secret key for apps)
      "minio_env" = {
        mode = "0400";
        owner = "root";
      };

      # Warehouse Management environment (JWT_SECRET)
      "warehouse_env" = {
        mode = "0400";
        owner = "root";
      };

      # Nix-pilot password
      "nix_pilot_password" = {
        mode = "0400";
        owner = "root";
      };

      # K3s cluster token (for multi-node support)
      # Initially auto-generated, add to secrets.yaml when expanding cluster
      # "k3s_token" = {
      #   mode = "0400";
      #   owner = "root";
      # };
    };
  };
}
