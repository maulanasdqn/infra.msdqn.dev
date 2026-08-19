{ lib, pkgs, ... }:
let

  kyaBiCiDeploy = pkgs.writeShellScript "kya-bi-ci-deploy" ''
    set -euo pipefail
    umask 077
    rm -rf /opt/kya-bid-intake
    mkdir -p /opt/kya-bid-intake
    ${pkgs.gnutar}/bin/tar -xf - -C /opt/kya-bid-intake
    cd /opt/kya-bid-intake
    ${pkgs.podman}/bin/podman build --net=host \
      -f apps/bid-intake/Dockerfile -t localhost/kya-bid-intake:latest .
    ${pkgs.systemd}/bin/systemctl restart kya-bi-migrate.service
    ${pkgs.systemd}/bin/systemctl restart kya-bi.service
    ${pkgs.systemd}/bin/systemctl restart kya-bi-worker.service
    app_ok=0
    for _ in $(seq 1 45); do
      if ${pkgs.curl}/bin/curl -sf --connect-timeout 5 --max-time 10 http://127.0.0.1:3007/healthz >/dev/null 2>&1; then
        app_ok=1
        break
      fi
      sleep 2
    done
    if [ "$app_ok" != 1 ]; then
      echo "kya-bi healthcheck failed after restart" >&2
      exit 1
    fi
    for _ in $(seq 1 30); do
      if [ "$(${pkgs.podman}/bin/podman inspect -f '{{.State.Running}}' kya-bi-worker 2>/dev/null)" = "true" ]; then
        worker_id=$(${pkgs.podman}/bin/podman inspect -f '{{.Id}}' kya-bi-worker 2>/dev/null)
        sleep 10
        if [ -n "$worker_id" ] && [ "$(${pkgs.podman}/bin/podman inspect -f '{{.Id}}' kya-bi-worker 2>/dev/null)" = "$worker_id" ]; then
          ${pkgs.podman}/bin/podman image prune -f >/dev/null 2>&1 || true
          echo "kya-bi deploy OK"
          exit 0
        fi
        echo "kya-bi worker crash-looping after restart" >&2
        exit 1
      fi
      sleep 2
    done
    echo "kya-bi worker not running after restart" >&2
    exit 1
  '';
in
{

  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${kyaBiCiDeploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMVYsfPOR0YIR85nif+RuEHmuLhTa0NGWdGYPMF5E0ma kya-bi-ci-deploy''
  ];

  services.github-runners.kya-bi = {
    enable = true;
    name = "kya-bi-vps";
    url = "https://github.com/s52ai/kya-group";
    tokenFile = "/etc/github-runner-kya-bi.token";
    extraLabels = [ "kya-bi" ];
    workDir = "/var/lib/github-runner-work/kya-bi";
    serviceOverrides = {
      StateDirectory = lib.mkForce [
        "github-runner/kya-bi"
        "github-runner-work/kya-bi"
      ];
      BindPaths = lib.mkForce [ ];
      ExecPaths = [ "/var/lib/github-runner-work/kya-bi" ];
    };
    replace = true;
    extraPackages = with pkgs; [
      git
      openssh
    ];
  };

  virtualisation.oci-containers.containers.kya-bi-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/kya-bi/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/kya-bi-postgres.env" ];
    extraOptions = [
      "--network=kya-bi-net"
      "--memory=512m"
    ];
  };

  virtualisation.oci-containers.containers.kya-bi-redis = {
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
      "noeviction"
    ];
    extraOptions = [
      "--network=kya-bi-net"
      "--memory=192m"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kya-bi 0755 root root -"
    "d /var/lib/kya-bi/postgres 0700 70 70 -"
  ];

  systemd.services.kya-bi-network = {
    description = "Create KYA bid-intake podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-kya-bi-postgres.service"
      "podman-kya-bi-redis.service"
      "kya-bi-migrate.service"
      "kya-bi.service"
      "kya-bi-worker.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create kya-bi-net --ignore";
    };
  };

  systemd.services.kya-bi-migrate = {
    description = "KYA bid-intake DB migrate + bootstrap admin";
    after = [
      "podman-kya-bi-postgres.service"
      "kya-bi-network.service"
    ];
    requires = [
      "podman-kya-bi-postgres.service"
      "kya-bi-network.service"
    ];
    before = [
      "kya-bi.service"
      "kya-bi-worker.service"
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
        if $PODMAN exec kya-bi-postgres pg_isready -U kya -d bid_intake >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done
      $PODMAN run --rm --network=kya-bi-net --env-file /etc/kya-bi.env \
        localhost/kya-bid-intake:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/migrate.ts
      $PODMAN run --rm --network=kya-bi-net --env-file /etc/kya-bi.env \
        localhost/kya-bid-intake:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/bootstrap-admin.ts || true
    '';
  };

  systemd.services.kya-bi = {
    description = "KYA bid-intake app";
    after = [
      "kya-bi-migrate.service"
      "kya-bi-network.service"
      "podman-kya-bi-redis.service"
    ];
    requires = [
      "kya-bi-migrate.service"
      "kya-bi-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-bi";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-bi \
          --network=kya-bi-net \
          -p 127.0.0.1:3007:3007 \
          --env-file /etc/kya-bi.env \
          -e REDIS_URL=redis://kya-bi-redis:6379/6 \
          localhost/kya-bid-intake:latest
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-bi";
    };
  };

  systemd.services.kya-bi-worker = {
    description = "KYA bid-intake BullMQ worker";
    after = [
      "kya-bi-migrate.service"
      "kya-bi-network.service"
      "podman-kya-bi-redis.service"
    ];
    requires = [
      "kya-bi-migrate.service"
      "kya-bi-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 60;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-bi-worker";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-bi-worker \
          --network=kya-bi-net \
          --env-file /etc/kya-bi.env \
          -e REDIS_URL=redis://kya-bi-redis:6379/6 \
          localhost/kya-bid-intake:latest \
          /app/api/node_modules/.bin/tsx /app/api/src/worker.ts
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-bi-worker";
    };
  };

  services.nginx.virtualHosts."kya-bi.stynx.app" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3007";
      proxyWebsockets = true;
    };
  };
}
