{ lib, pkgs, ... }:
let

  kyaElCiDeploy = pkgs.writeShellScript "kya-el-ci-deploy" ''
    set -euo pipefail
    umask 077
    rm -rf /opt/kya-entity-license-renewal
    mkdir -p /opt/kya-entity-license-renewal
    ${pkgs.gnutar}/bin/tar -xf - -C /opt/kya-entity-license-renewal
    cd /opt/kya-entity-license-renewal
    ${pkgs.podman}/bin/podman build --net=host \
      -f apps/entity-license-renewal/Dockerfile -t localhost/kya-entity-license-renewal:latest .
    ${pkgs.systemd}/bin/systemctl restart kya-el-migrate.service
    ${pkgs.systemd}/bin/systemctl restart kya-el.service
    ${pkgs.systemd}/bin/systemctl restart kya-el-worker.service
    for _ in $(seq 1 45); do
      if ${pkgs.curl}/bin/curl -sf http://127.0.0.1:3005/healthz >/dev/null 2>&1; then
        ${pkgs.podman}/bin/podman image prune -f >/dev/null 2>&1 || true
        echo "kya-el deploy OK"
        exit 0
      fi
      sleep 2
    done
    echo "kya-el healthcheck failed after restart" >&2
    exit 1
  '';
in
{

  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${kyaElCiDeploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJ5lWhyZwDFGX0klU9XdzIBQ7d49Eux1Hlu4BYjZBkT kya-el-ci-deploy''
  ];

  services.github-runners.kya-el = {
    enable = true;
    name = "kya-el-vps";
    url = "https://github.com/s52ai/kya-group";
    tokenFile = "/etc/github-runner-kya-el.token";
    extraLabels = [ "kya-elr" ];
    workDir = "/var/lib/github-runner-work/kya-el";
    serviceOverrides = {
      StateDirectory = lib.mkForce [
        "github-runner/kya-el"
        "github-runner-work/kya-el"
      ];
      BindPaths = lib.mkForce [ ];
      ExecPaths = [ "/var/lib/github-runner-work/kya-el" ];
    };
    replace = true;
    extraPackages = with pkgs; [
      git
      openssh
    ];
  };

  virtualisation.oci-containers.containers.kya-el-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/kya-el/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/kya-el-postgres.env" ];
    extraOptions = [
      "--network=kya-el-net"
      "--memory=512m"
    ];
  };

  virtualisation.oci-containers.containers.kya-el-redis = {
    image = "redis:7-alpine";
    cmd = [
      "redis-server"
      "--save"
      ""
      "--appendonly"
      "no"
      "--maxmemory"
      "128mb"
      "--maxmemory-policy"
      "allkeys-lru"
    ];
    extraOptions = [
      "--network=kya-el-net"
      "--memory=192m"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kya-el 0755 root root -"
    "d /var/lib/kya-el/postgres 0700 70 70 -"
  ];

  systemd.services.kya-el-network = {
    description = "Create KYA entity-license-renewal podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-kya-el-postgres.service"
      "podman-kya-el-redis.service"
      "kya-el-migrate.service"
      "kya-el.service"
      "kya-el-worker.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create kya-el-net --ignore";
    };
  };

  systemd.services.kya-el-migrate = {
    description = "KYA entity-license-renewal DB migrate + bootstrap admin";
    after = [
      "podman-kya-el-postgres.service"
      "kya-el-network.service"
    ];
    requires = [
      "podman-kya-el-postgres.service"
      "kya-el-network.service"
    ];
    before = [ "kya-el.service" "kya-el-worker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      PODMAN=${pkgs.podman}/bin/podman
      for _ in $(seq 1 60); do
        if $PODMAN exec kya-el-postgres pg_isready -U kya -d entity_license_renewal >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done
      $PODMAN run --rm --network=kya-el-net --env-file /etc/kya-el.env \
        localhost/kya-entity-license-renewal:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/migrate.ts
      $PODMAN run --rm --network=kya-el-net --env-file /etc/kya-el.env \
        localhost/kya-entity-license-renewal:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/bootstrap-admin.ts
    '';
  };

  systemd.services.kya-el = {
    description = "KYA entity-license-renewal app";
    after = [
      "kya-el-migrate.service"
      "kya-el-network.service"
      "podman-kya-el-redis.service"
    ];
    requires = [
      "kya-el-migrate.service"
      "kya-el-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-el";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-el \
          --network=kya-el-net \
          -p 127.0.0.1:3005:3005 \
          --env-file /etc/kya-el.env \
          -e REDIS_URL=redis://kya-el-redis:6379/4 \
          localhost/kya-entity-license-renewal:latest
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-el";
    };
  };

  systemd.services.kya-el-worker = {
    description = "KYA entity-license-renewal BullMQ worker";
    after = [
      "kya-el-migrate.service"
      "kya-el-network.service"
      "podman-kya-el-redis.service"
    ];
    requires = [
      "kya-el-migrate.service"
      "kya-el-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 60;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-el-worker";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-el-worker \
          --network=kya-el-net \
          --env-file /etc/kya-el.env \
          -e REDIS_URL=redis://kya-el-redis:6379/4 \
          localhost/kya-entity-license-renewal:latest \
          /app/api/node_modules/.bin/tsx /app/api/src/worker.ts
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-el-worker";
    };
  };

  services.nginx.virtualHosts."kya-el.stynx.app" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3005";
      proxyWebsockets = true;
    };
  };
}
