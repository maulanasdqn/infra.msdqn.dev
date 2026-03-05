{
  lib,
  pkgs,
  acmeEmail,
  config,
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
    additionalModules = [ pkgs.nginxModules.brotli ]; # Load brotli module for app modules that use it
    recommendedGzipSettings = lib.mkForce false; # Force disabled - app modules add their own gzip settings
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedBrotliSettings = lib.mkForce false; # Force disabled - app modules add their own brotli settings
    sslCiphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    proxyTimeout = "300s";
    appendHttpConfig = ''
      ssl_ecdh_curve X25519:secp384r1:prime256v1;
      ssl_conf_command Groups X25519:secp384r1:prime256v1;
      proxy_headers_hash_max_size 1024;
      proxy_headers_hash_bucket_size 128;

      # ===== RATE LIMITING ZONES =====
      # General API rate limit: 10 requests/second per IP
      limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

      # Strict limit for auth endpoints: 5 requests/second
      limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=5r/s;

      # Static assets: 50 requests/second (more permissive)
      limit_req_zone $binary_remote_addr zone=static_limit:10m rate=50r/s;

      # AI/LLM endpoints: 2 requests/second (expensive operations)
      limit_req_zone $binary_remote_addr zone=ai_limit:10m rate=2r/s;

      # Upload endpoints: 5 requests/minute
      limit_req_zone $binary_remote_addr zone=upload_limit:10m rate=5r/m;

      # Connection limits per IP
      limit_conn_zone $binary_remote_addr zone=conn_per_ip:10m;

      # ===== SECURITY SETTINGS =====
      # Note: server_tokens is already set by recommendedOptimisation

      # Request size limits
      client_max_body_size 100m;
      client_body_buffer_size 128k;

      # Timeouts for DDoS protection
      client_body_timeout 10s;
      client_header_timeout 10s;
      keepalive_timeout 30s;
      send_timeout 10s;

      # Rate limit response
      limit_req_status 429;
      limit_conn_status 429;
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
      # Authentication failures
      nginx-http-auth = {
        settings = {
          enabled = true;
          port = "http,https";
          filter = "nginx-http-auth";
          maxretry = 3;
          bantime = "1h";
        };
      };
      # Bot detection
      nginx-botsearch = {
        settings = {
          enabled = true;
          port = "http,https";
          filter = "nginx-botsearch";
          maxretry = 5;
          bantime = "1h";
        };
      };
      # Rate limit violations (429 responses)
      nginx-limit-req = {
        settings = {
          enabled = true;
          port = "http,https";
          filter = "nginx-limit-req";
          maxretry = 10;
          findtime = "1m";
          bantime = "10m";
        };
      };
      # Bad requests (400 errors - potential scanner)
      nginx-bad-request = {
        settings = {
          enabled = true;
          port = "http,https";
          filter = "nginx-bad-request";
          maxretry = 20;
          findtime = "1m";
          bantime = "30m";
        };
      };
      # Repeated 403/404 - potential scanner
      nginx-req-limit = {
        settings = {
          enabled = true;
          port = "http,https";
          logpath = "/var/log/nginx/access.log";
          maxretry = 100;
          findtime = "1m";
          bantime = "30m";
        };
      };
    };
  };

  # Custom fail2ban filters
  environment.etc = {
    "fail2ban/filter.d/nginx-bad-request.local".text = ''
      [Definition]
      failregex = ^<HOST> .* "(GET|POST|HEAD|PUT|DELETE|PATCH).*" 400
      ignoreregex =
    '';
    "fail2ban/filter.d/nginx-req-limit.local".text = ''
      [Definition]
      failregex = ^<HOST> .* "(GET|POST|HEAD|PUT|DELETE|PATCH).*" (403|404)
      ignoreregex = \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|svg)
    '';
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
