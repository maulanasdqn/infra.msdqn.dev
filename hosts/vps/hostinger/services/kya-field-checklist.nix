{ lib, pkgs, ... }:
let

  kyaFcCiDeploy = pkgs.writeShellScript "kya-fc-ci-deploy" ''
    set -euo pipefail
    umask 077
    rm -rf /opt/kya-field-checklist
    mkdir -p /opt/kya-field-checklist
    ${pkgs.gnutar}/bin/tar -xf - -C /opt/kya-field-checklist
    cd /opt/kya-field-checklist
    ${pkgs.podman}/bin/podman build --net=host \
      -f apps/field-checklist/Dockerfile -t localhost/kya-field-checklist:latest .
    ${pkgs.systemd}/bin/systemctl restart kya-fc-migrate.service
    ${pkgs.systemd}/bin/systemctl restart kya-fc.service
    ${pkgs.systemd}/bin/systemctl restart kya-fc-worker.service
    for _ in $(seq 1 45); do
      if ${pkgs.curl}/bin/curl -sf http://127.0.0.1:3006/healthz >/dev/null 2>&1; then
        ${pkgs.podman}/bin/podman image prune -f >/dev/null 2>&1 || true
        echo "kya-fc deploy OK"
        exit 0
      fi
      sleep 2
    done
    echo "kya-fc healthcheck failed after restart" >&2
    exit 1
  '';
in
{

  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${kyaFcCiDeploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGpu2WruXV2+KcVh4I3EMLUJhv14wQnchW4uULvHhRkr kya-fc-ci-deploy''
  ];

  services.github-runners.kya-fc = {
    enable = true;
    name = "kya-fc-vps";
    url = "https://github.com/s52ai/kya-group";
    tokenFile = "/etc/github-runner-kya-fc.token";
    extraLabels = [ "kya-fc" ];
    workDir = "/var/lib/github-runner-work/kya-fc";
    serviceOverrides = {
      StateDirectory = lib.mkForce [
        "github-runner/kya-fc"
        "github-runner-work/kya-fc"
      ];
      BindPaths = lib.mkForce [ ];
      ExecPaths = [ "/var/lib/github-runner-work/kya-fc" ];
    };
    replace = true;
    extraPackages = with pkgs; [
      git
      openssh
    ];
  };

  virtualisation.oci-containers.containers.kya-fc-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/kya-fc/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/kya-fc-postgres.env" ];
    extraOptions = [
      "--network=kya-fc-net"
      "--memory=512m"
    ];
  };

  virtualisation.oci-containers.containers.kya-fc-redis = {
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
      "--network=kya-fc-net"
      "--memory=192m"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kya-fc 0755 root root -"
    "d /var/lib/kya-fc/postgres 0700 70 70 -"
  ];

  systemd.services.kya-fc-network = {
    description = "Create KYA field-checklist podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-kya-fc-postgres.service"
      "podman-kya-fc-redis.service"
      "kya-fc-migrate.service"
      "kya-fc.service"
      "kya-fc-worker.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create kya-fc-net --ignore";
    };
  };

  systemd.services.kya-fc-migrate = {
    description = "KYA field-checklist DB migrate + bootstrap admin";
    after = [
      "podman-kya-fc-postgres.service"
      "kya-fc-network.service"
    ];
    requires = [
      "podman-kya-fc-postgres.service"
      "kya-fc-network.service"
    ];
    before = [
      "kya-fc.service"
      "kya-fc-worker.service"
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
        if $PODMAN exec kya-fc-postgres pg_isready -U kya -d field_checklist >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done
      $PODMAN run --rm --network=kya-fc-net --env-file /etc/kya-fc.env \
        localhost/kya-field-checklist:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/migrate.ts
      $PODMAN run --rm --network=kya-fc-net --env-file /etc/kya-fc.env \
        localhost/kya-field-checklist:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/bootstrap-admin.ts || true
    '';
  };

  systemd.services.kya-fc = {
    description = "KYA field-checklist app";
    after = [
      "kya-fc-migrate.service"
      "kya-fc-network.service"
      "podman-kya-fc-redis.service"
    ];
    requires = [
      "kya-fc-migrate.service"
      "kya-fc-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-fc";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-fc \
          --network=kya-fc-net \
          -p 127.0.0.1:3006:3006 \
          --env-file /etc/kya-fc.env \
          -e REDIS_URL=redis://kya-fc-redis:6379/5 \
          localhost/kya-field-checklist:latest
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-fc";
    };
  };

  systemd.services.kya-fc-worker = {
    description = "KYA field-checklist BullMQ worker";
    after = [
      "kya-fc-migrate.service"
      "kya-fc-network.service"
      "podman-kya-fc-redis.service"
    ];
    requires = [
      "kya-fc-migrate.service"
      "kya-fc-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 60;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-fc-worker";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-fc-worker \
          --network=kya-fc-net \
          --env-file /etc/kya-fc.env \
          -e REDIS_URL=redis://kya-fc-redis:6379/5 \
          localhost/kya-field-checklist:latest \
          /app/api/node_modules/.bin/tsx /app/api/src/worker.ts
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-fc-worker";
    };
  };

  services.nginx.virtualHosts."kya-fc.stynx.app" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3006";
      proxyWebsockets = true;
    };
  };
}
