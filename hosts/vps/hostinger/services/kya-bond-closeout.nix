{ lib, pkgs, ... }:
let

  kyaBcCiDeploy = pkgs.writeShellScript "kya-bc-ci-deploy" ''
    set -euo pipefail
    umask 077
    rm -rf /opt/kya-bond-closeout
    mkdir -p /opt/kya-bond-closeout
    ${pkgs.gnutar}/bin/tar -xf - -C /opt/kya-bond-closeout
    cd /opt/kya-bond-closeout
    ${pkgs.podman}/bin/podman build --net=host \
      -f apps/bond-closeout/Dockerfile -t localhost/kya-bond-closeout:latest .
    ${pkgs.systemd}/bin/systemctl restart kya-bc-migrate.service
    ${pkgs.systemd}/bin/systemctl restart kya-bc.service
    for _ in $(seq 1 45); do
      if ${pkgs.curl}/bin/curl -sf http://127.0.0.1:3004/healthz >/dev/null 2>&1; then
        ${pkgs.podman}/bin/podman image prune -f >/dev/null 2>&1 || true
        echo "kya-bc deploy OK"
        exit 0
      fi
      sleep 2
    done
    echo "kya-bc healthcheck failed after restart" >&2
    exit 1
  '';
in
{

  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${kyaBcCiDeploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSGiOb1gvXdNYWKXJizrm3NtZBxddBUIaNA52L3HAFF kya-bc-ci-deploy''
  ];

  services.github-runners.kya-bc = {
    enable = true;
    name = "kya-bc-vps";
    url = "https://github.com/s52ai/kya-group";
    tokenFile = "/etc/github-runner-kya-bc.token";
    extraLabels = [ "kya-bc" ];
    workDir = "/var/lib/github-runner-work/kya-bc";
    serviceOverrides = {
      StateDirectory = lib.mkForce [
        "github-runner/kya-bc"
        "github-runner-work/kya-bc"
      ];
      BindPaths = lib.mkForce [ ];
      ExecPaths = [ "/var/lib/github-runner-work/kya-bc" ];
    };
    replace = true;
    extraPackages = with pkgs; [
      git
      openssh
    ];
  };

  virtualisation.oci-containers.containers.kya-bc-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/kya-bc/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/kya-bc-postgres.env" ];
    extraOptions = [
      "--network=kya-bc-net"
      "--memory=512m"
    ];
  };

  virtualisation.oci-containers.containers.kya-bc-redis = {
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
      "--network=kya-bc-net"
      "--memory=192m"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kya-bc 0755 root root -"
    "d /var/lib/kya-bc/postgres 0700 70 70 -"
  ];

  systemd.services.kya-bc-network = {
    description = "Create KYA bond-closeout podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-kya-bc-postgres.service"
      "podman-kya-bc-redis.service"
      "kya-bc-migrate.service"
      "kya-bc.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create kya-bc-net --ignore";
    };
  };

  systemd.services.kya-bc-migrate = {
    description = "KYA bond-closeout DB migrate + bootstrap admin";
    after = [
      "podman-kya-bc-postgres.service"
      "kya-bc-network.service"
    ];
    requires = [
      "podman-kya-bc-postgres.service"
      "kya-bc-network.service"
    ];
    before = [ "kya-bc.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      PODMAN=${pkgs.podman}/bin/podman
      for _ in $(seq 1 60); do
        if $PODMAN exec kya-bc-postgres pg_isready -U kya -d bond_closeout >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done
      $PODMAN run --rm --network=kya-bc-net --env-file /etc/kya-bc.env \
        localhost/kya-bond-closeout:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/migrate.ts
      $PODMAN run --rm --network=kya-bc-net --env-file /etc/kya-bc.env \
        localhost/kya-bond-closeout:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/bootstrap-admin.ts
    '';
  };

  systemd.services.kya-bc = {
    description = "KYA bond-closeout app";
    after = [
      "kya-bc-migrate.service"
      "kya-bc-network.service"
      "podman-kya-bc-redis.service"
    ];
    requires = [
      "kya-bc-migrate.service"
      "kya-bc-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-bc";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-bc \
          --network=kya-bc-net \
          -p 127.0.0.1:3004:3004 \
          --env-file /etc/kya-bc.env \
          -e REDIS_URL=redis://kya-bc-redis:6379 \
          localhost/kya-bond-closeout:latest
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-bc";
    };
  };

  services.nginx.virtualHosts."kya-bc.stynx.app" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3004";
      proxyWebsockets = true;
    };
  };
}
