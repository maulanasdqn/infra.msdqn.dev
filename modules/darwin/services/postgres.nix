{ pkgs, lib, enableAggressiveTweaks ? false, ... }:
let
  # Off: dev databases live in containers under Colima, and this daemon was failing
  # to start anyway (org.nixos.postgresql exited 2 at every login). Flip to true to
  # bring the system-wide server back.
  enablePostgres = false;
in
{
  # System-wide PostgreSQL (port 5433, trust auth) — single-owner machines only.
  services.postgresql = lib.mkIf (enableAggressiveTweaks && enablePostgres) {
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
