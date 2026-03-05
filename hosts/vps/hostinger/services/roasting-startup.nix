{ config, acmeEmail, ... }:
{
  services.roasting-startup = {
    enable = true;
    port = 7676;
    host = "0.0.0.0";  # Bind to all interfaces for k8s access
    domain = "roast.kilat.app";
    # Disable nginx - handled by k8s nginx-ingress
    nginx.enable = false;

    # Secrets file containing:
    # - DATABASE_URL
    # - OPENROUTER_API_KEY
    # - GOOGLE_CLIENT_ID
    # - GOOGLE_CLIENT_SECRET
    # - GOOGLE_REDIRECT_URI=https://roast.kilat.app/auth/callback
    environmentFile = config.sops.secrets.roasting_startup_env.path;
  };

  # Ensure roasting-startup service starts after sops secrets are available
  systemd.services.roasting-startup = {
    after = [ "sops-nix.service" "postgresql.service" ];
    wants = [ "sops-nix.service" ];
  };
}
