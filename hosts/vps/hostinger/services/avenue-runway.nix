{ lib, pkgs, ... }:
let

  runwayRun = name: extra: command: ''
    ${pkgs.podman}/bin/podman run --rm --name ${name} \
      --network=avenue-runway-net \
      --env-file /etc/avenue-runway.env \
      -e WEB_DIST_PATH=/app/apps/web/dist \
      -w /app \
      ${extra} \
      localhost/avenue-runway:latest \
      ${command}
  '';
in
{

  virtualisation.oci-containers.containers.avenue-runway-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/avenue-runway/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/avenue-runway-postgres.env" ];
    extraOptions = [
      "--network=avenue-runway-net"
      "--memory=768m"
    ];
  };

  virtualisation.oci-containers.containers.avenue-runway-redis = {
    image = "redis:7-alpine";
    cmd = [
      "redis-server"
      "--appendonly"
      "yes"
    ];
    volumes = [ "/var/lib/avenue-runway/redis:/data" ];
    extraOptions = [
      "--network=avenue-runway-net"
      "--memory=256m"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/avenue-runway 0755 root root -"
    "d /var/lib/avenue-runway/postgres 0700 70 70 -"
    "d /var/lib/avenue-runway/redis 0755 999 999 -"
  ];

  systemd.services.avenue-runway-network = {
    description = "Create avenue-runway podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-avenue-runway-postgres.service"
      "podman-avenue-runway-redis.service"
      "avenue-runway-migrate.service"
      "avenue-runway.service"
      "avenue-runway-scheduler.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create avenue-runway-net --ignore";
    };
  };

  systemd.services.avenue-runway-migrate = {
    description = "avenue-runway DB prepare + push + bootstrap admin";
    after = [
      "podman-avenue-runway-postgres.service"
      "podman-avenue-runway-redis.service"
      "avenue-runway-network.service"
    ];
    requires = [
      "podman-avenue-runway-postgres.service"
      "avenue-runway-network.service"
    ];
    before = [
      "avenue-runway.service"
      "avenue-runway-scheduler.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      PODMAN=${pkgs.podman}/bin/podman
      for _ in $(seq 1 60); do
        if $PODMAN exec avenue-runway-postgres pg_isready -U runway -d avenue_runway >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done
      $PODMAN run --rm --network=avenue-runway-net --env-file /etc/avenue-runway.env \
        localhost/avenue-runway:latest \
        pnpm --filter @app/api db:prepare
      $PODMAN run --rm --network=avenue-runway-net --env-file /etc/avenue-runway.env \
        localhost/avenue-runway:latest \
        pnpm --filter @app/api db:push
      $PODMAN run --rm --network=avenue-runway-net --env-file /etc/avenue-runway.env \
        localhost/avenue-runway:latest \
        pnpm --filter @app/api seed:e2e-admin
    '';
  };

  systemd.services.avenue-runway = {
    description = "avenue-runway API + SPA";
    after = [
      "avenue-runway-migrate.service"
      "avenue-runway-network.service"
    ];
    requires = [
      "avenue-runway-migrate.service"
      "avenue-runway-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f avenue-runway";
      ExecStart = runwayRun "avenue-runway" "-p 127.0.0.1:3100:3000" "pnpm --filter @app/api start";
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 avenue-runway";
    };
  };

  systemd.services.avenue-runway-scheduler = {
    description = "avenue-runway cron scheduler";
    after = [
      "avenue-runway.service"
      "avenue-runway-network.service"
    ];
    requires = [
      "avenue-runway-migrate.service"
      "avenue-runway-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 10;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f avenue-runway-scheduler";
      ExecStart = runwayRun "avenue-runway-scheduler" "" "pnpm --filter @app/api scheduler";
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 avenue-runway-scheduler";
    };
  };

  services.nginx.virtualHosts."runway.msdqn.dev" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3100";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
        proxy_read_timeout 700s;
        proxy_send_timeout 700s;
      '';
    };
  };

  services.nginx.virtualHosts."runway.stynx.app" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3100";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
        proxy_read_timeout 700s;
        proxy_send_timeout 700s;
      '';
    };
  };
}
