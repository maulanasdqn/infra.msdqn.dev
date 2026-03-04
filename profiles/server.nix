{
  lib,
  pkgs,
  acmeEmail,
  ...
}:
{
  imports = [
    ./base.nix
  ];

  # Enable zram swap to prevent OOM during builds
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;  # Use 50% of RAM as compressed swap
  };

  # Limit Nix build parallelism to prevent OOM
  nix.settings = {
    max-jobs = 1;  # Only 1 build job at a time
    cores = 2;     # Use max 2 cores per build
    substituters = [
      "https://cache.nixos.org"
      "https://msdqn.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "msdqn.cachix.org-1:I5z8egjNf2iKYLwLGF2REfpELlFoUdaSLsh7dQk1a+o="
    ];
  };

  time.timeZone = lib.mkForce "UTC";

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = false;

    firewall = {
      enable = true;
      allowPing = lib.mkForce false;  # Security: disable ping responses
      logReversePathDrops = true;
      logRefusedConnections = true;
      allowedTCPPorts = [
        22   # SSH
        80   # HTTP (nginx)
        443  # HTTPS (nginx)
      ];
      allowedUDPPorts = [ ];
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      AllowTcpForwarding = false;
      AllowAgentForwarding = false;
      PermitEmptyPasswords = false;
      MaxAuthTries = 3;
      LoginGraceTime = 20;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedBrotliSettings = lib.mkForce false; # Force disabled - app modules add their own brotli settings
    sslCiphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    appendHttpConfig = ''
      ssl_ecdh_curve X25519:secp384r1:prime256v1;
      ssl_conf_command Groups X25519:secp384r1:prime256v1;
    '';

    virtualHosts."_" = {
      default = true;
      locations."/" = {
        return = "200 'NixOS VPS is running!'";
        extraConfig = ''
          add_header Content-Type text/plain;
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = acmeEmail;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "168h";  # 1 week max ban
      multipliers = "1 2 4 8 16 32 64";
    };
    jails = {
      nginx-http-auth = {
        settings = {
          enabled = true;
          port = "http,https";
          filter = "nginx-http-auth";
          maxretry = 3;
          bantime = "1h";
        };
      };
      nginx-botsearch = {
        settings = {
          enabled = true;
          port = "http,https";
          filter = "nginx-botsearch";
          maxretry = 5;
          bantime = "1h";
        };
      };
    };
  };

  boot.kernel.sysctl = {
    # Network hardening
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # Disable source routing
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;

    # Kernel hardening
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.perf_event_paranoid" = 3;
    "kernel.yama.ptrace_scope" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;

    # TCP hardening
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.tcp_timestamps" = 0;
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "65536";
    }
  ];

  # Use podman instead of docker
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    defaultNetwork.settings.dns_enabled = true;
  };

  # Enable container networking
  virtualisation.oci-containers.backend = "podman";

  # Disable auto-upgrade - use manual deploys from GitHub
  system.autoUpgrade.enable = false;

  services.logrotate.enable = true;
  services.avahi.enable = false;
  services.printing.enable = false;

  # Additional security hardening
  security.protectKernelImage = true;
  security.lockKernelModules = false;  # Required for containers

  # Audit logging
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      "-a exit,always -F arch=b64 -S execve"  # Log all executions
    ];
  };

  # Disable unnecessary services
  services.xserver.enable = false;

  environment.systemPackages = with pkgs; [
    # System monitoring
    htop
    iotop
    ncdu
    bottom

    # Utilities
    tmux
    ripgrep
    fd
    jq
    yq
    curl
    wget
    git

    # Container management
    podman-compose

    # Security tools
    lynis        # Security auditing
    unhide       # Forensic tool to find hidden processes
  ];

}
