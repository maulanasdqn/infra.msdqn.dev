{ pkgs, ... }:
let
  # CI/CD deploy: GitHub Actions (s52ai/kya-group, deploy-bill-pay.yml) pipes
  # `git archive HEAD` over SSH into this forced-command script — it rebuilds the
  # image on the VPS and restarts the app + its BullMQ worker. The CI key can run
  # ONLY this script (restrict + command=), never an arbitrary root shell.
  kyaBpCiDeploy = pkgs.writeShellScript "kya-bp-ci-deploy" ''
    set -euo pipefail
    umask 077
    rm -rf /opt/kya-bill-pay
    mkdir -p /opt/kya-bill-pay
    ${pkgs.gnutar}/bin/tar -xf - -C /opt/kya-bill-pay
    cd /opt/kya-bill-pay
    ${pkgs.podman}/bin/podman build --net=host \
      -f apps/bill-pay/Dockerfile -t localhost/kya-bill-pay:latest .
    # Apply DB migrations with the freshly-built image BEFORE rolling the app.
    # restart re-runs the oneshot and blocks on it — a failed migration aborts
    # here (set -e) and leaves the old app + worker running.
    ${pkgs.systemd}/bin/systemctl restart kya-bp-migrate.service
    ${pkgs.systemd}/bin/systemctl restart kya-bp.service
    ${pkgs.systemd}/bin/systemctl restart kya-bp-worker.service
    for _ in $(seq 1 45); do
      if ${pkgs.curl}/bin/curl -sf http://127.0.0.1:3005/healthz >/dev/null 2>&1; then
        ${pkgs.podman}/bin/podman image prune -f >/dev/null 2>&1 || true
        echo "kya-bp deploy OK"
        exit 0
      fi
      sleep 2
    done
    echo "kya-bp healthcheck failed after restart" >&2
    exit 1
  '';
in
{
  # KYA bill-pay ("AP Invoice Automation") — same shape as kya-sales-reporting.nix,
  # on port 3005 with its own Postgres, Redis, podman network, runner and
  # forced-command key, PLUS a second app container running the BullMQ worker
  # (worker.ts). Nothing is shared with the other kya apps except the box.
  # Secrets are read from env files created on the VPS (0600):
  #   /etc/kya-bp-postgres.env  POSTGRES_USER/PASSWORD/DB (DB = bill_pay)
  #   /etc/kya-bp.env           DATABASE_URL, BETTER_AUTH_*, WEB_ORIGIN, and the
  #                             optional ANTHROPIC / GMAIL_* / SAGE_* / SHEETS_* /
  #                             PHASE2_BILLS_ENABLED integration secrets.

  # NOTE: replace the placeholder below with the real kya-bp CI deploy PUBLIC key
  # (ssh-keygen -t ed25519 -C kya-bp-ci-deploy); its private half goes into the
  # GitHub Actions secret VPS_SSH_KEY_BP on s52ai/kya-group.
  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${kyaBpCiDeploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICucFpY4kNeawx8trOIq6ZRSeUMLU6esPAaPdqFuClRP kya-bp-ci-deploy''
  ];

  # Self-hosted runner, labelled kya-bp so deploy-bill-pay.yml lands here.
  # Registration token in /etc/github-runner-kya-bp.token (0600, created on the
  # VPS; refresh with:
  #   gh api -X POST repos/s52ai/kya-group/actions/runners/registration-token --jq .token).
  services.github-runners.kya-bp = {
    enable = true;
    name = "kya-bp-vps";
    url = "https://github.com/s52ai/kya-group";
    tokenFile = "/etc/github-runner-kya-bp.token";
    extraLabels = [ "kya-bp" ];
    replace = true;
    extraPackages = with pkgs; [ git openssh ];
  };

  virtualisation.oci-containers.containers.kya-bp-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/kya-bp/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/kya-bp-postgres.env" ];
    extraOptions = [ "--network=kya-bp-net" "--memory=512m" ];
  };

  virtualisation.oci-containers.containers.kya-bp-redis = {
    image = "redis:7-alpine";
    cmd = [
      "redis-server"
      "--save"
      ""
      "--appendonly"
      "no"
      "--maxmemory"
      "192mb"
      "--maxmemory-policy"
      "noeviction"
    ];
    extraOptions = [ "--network=kya-bp-net" "--memory=256m" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kya-bp 0755 root root -"
    "d /var/lib/kya-bp/postgres 0700 70 70 -"
  ];

  systemd.services.kya-bp-network = {
    description = "Create KYA bill-pay podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-kya-bp-postgres.service"
      "podman-kya-bp-redis.service"
      "kya-bp-migrate.service"
      "kya-bp.service"
      "kya-bp-worker.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create kya-bp-net --ignore";
    };
  };

  systemd.services.kya-bp-migrate = {
    description = "KYA bill-pay DB migrate + bootstrap admin";
    after = [ "podman-kya-bp-postgres.service" "kya-bp-network.service" ];
    requires = [ "podman-kya-bp-postgres.service" "kya-bp-network.service" ];
    before = [ "kya-bp.service" "kya-bp-worker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      PODMAN=${pkgs.podman}/bin/podman
      for _ in $(seq 1 60); do
        if $PODMAN exec kya-bp-postgres pg_isready -U kya -d bill_pay >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done
      $PODMAN run --rm --network=kya-bp-net --env-file /etc/kya-bp.env \
        localhost/kya-bill-pay:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/migrate.ts
      $PODMAN run --rm --network=kya-bp-net --env-file /etc/kya-bp.env \
        localhost/kya-bill-pay:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/bootstrap-admin.ts
    '';
  };

  systemd.services.kya-bp = {
    description = "KYA bill-pay app";
    after = [
      "kya-bp-migrate.service"
      "kya-bp-network.service"
      "podman-kya-bp-redis.service"
    ];
    requires = [ "kya-bp-migrate.service" "kya-bp-network.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-bp";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-bp \
          --network=kya-bp-net \
          -p 127.0.0.1:3005:3001 \
          --env-file /etc/kya-bp.env \
          -e REDIS_URL=redis://kya-bp-redis:6379 \
          localhost/kya-bill-pay:latest
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-bp";
    };
  };

  systemd.services.kya-bp-worker = {
    description = "KYA bill-pay BullMQ worker";
    after = [
      "kya-bp-migrate.service"
      "kya-bp-network.service"
      "podman-kya-bp-redis.service"
    ];
    requires = [ "kya-bp-migrate.service" "kya-bp-network.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-bp-worker";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-bp-worker \
          --network=kya-bp-net \
          --env-file /etc/kya-bp.env \
          -e REDIS_URL=redis://kya-bp-redis:6379 \
          localhost/kya-bill-pay:latest \
          /app/api/node_modules/.bin/tsx /app/api/src/worker.ts
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-bp-worker";
    };
  };

  # Served at kya-bp.stynx.app (Cloudflare DNS → A record to 72.62.125.38,
  # DNS-only/grey-cloud so ACME HTTP-01 reaches the origin).
  services.nginx.virtualHosts."kya-bp.stynx.app" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3005";
      proxyWebsockets = true;
    };
  };
}
