{ pkgs, lib, enableAggressiveTweaks ? false, ... }:
{
  # System-wide PostgreSQL (port 5433, trust auth) — single-owner machines only.
  services.postgresql = lib.mkIf enableAggressiveTweaks {
    enable = true;
    package = pkgs.postgresql_17;
    settings = {
      max_connections = 300;
      shared_buffers = "256MB";
      log_connections = false;
      port = pkgs.lib.mkForce 5433;
    };
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128      trust
    '';
  };
}
