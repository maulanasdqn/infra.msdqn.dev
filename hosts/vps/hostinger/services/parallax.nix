{ pkgs, ... }:
let
  parallax = pkgs.callPackage ../../../../pkgs/parallax { };
in
{
  networking.firewall.allowedTCPPorts = [ 1080 ];

  systemd.services.parallax = {
    description = "Parallax SOCKS5/HTTP proxy server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${parallax}/bin/parallax-server";
      Restart = "on-failure";
      RestartSec = 5;
      DynamicUser = true;
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
    };
    environment = {
      PROXY_LISTEN = "0.0.0.0:1080";
      RUST_LOG = "info";
    };
  };
}
