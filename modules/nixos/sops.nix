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
    };
  };
}
