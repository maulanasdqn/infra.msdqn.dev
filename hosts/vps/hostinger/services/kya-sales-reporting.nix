{ pkgs, ... }:
let
  # CI/CD deploy: GitHub Actions (s52ai/kya-group, deploy-sales-reporting.yml)
  # pipes `git archive HEAD` over SSH into this forced-command script — it
  # rebuilds the image on the VPS and restarts the app. The CI key can run ONLY
  # this script (restrict + command=), never an arbitrary root shell.
  kyaSrCiDeploy = pkgs.writeShellScript "kya-sr-ci-deploy" ''
    set -euo pipefail
    umask 077
    rm -rf /opt/kya-sales-reporting
    mkdir -p /opt/kya-sales-reporting
    ${pkgs.gnutar}/bin/tar -xf - -C /opt/kya-sales-reporting
    cd /opt/kya-sales-reporting
    ${pkgs.podman}/bin/podman build --net=host \
      -f apps/sales-reporting/Dockerfile -t localhost/kya-sales-reporting:latest .
    # Apply DB migrations + bootstrap with the freshly-built image BEFORE rolling
    # the app. restart re-runs the oneshot and blocks on it — a failed migration
    # aborts here (set -e) and leaves the old app running.
    ${pkgs.systemd}/bin/systemctl restart kya-sr-migrate.service
    ${pkgs.systemd}/bin/systemctl restart kya-sr.service
    for _ in $(seq 1 30); do
      if ${pkgs.curl}/bin/curl -sf http://127.0.0.1:3002/healthz >/dev/null 2>&1; then
        echo "kya-sr deploy OK"
        exit 0
      fi
      sleep 2
    done
    echo "kya-sr healthcheck failed after restart" >&2
    exit 1
  '';
in
{
  # KYA sales-reporting ("Sales Reconciliation & Commission Dashboard") — same
  # shape as kya-field-quote.nix, on port 3002 with its own Postgres, podman
  # network, runner and forced-command key. Nothing is shared with kya-fq except
  # the box. Secrets are read from env files created on the VPS (0600):
  #   /etc/kya-sr-postgres.env  POSTGRES_USER/PASSWORD/DB
  #   /etc/kya-sr.env           DATABASE_URL, BETTER_AUTH_*, WEB_ORIGIN, admin bootstrap

  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${kyaSrCiDeploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1QIz+011BymMfk/f3sxZ5HzUAI0M3jxMtlpdryQEI4 kya-sr-ci-deploy''
  ];

  # Second self-hosted runner, labelled kya-sr so deploy-sales-reporting.yml
  # lands here and not on the field-quote runner. Registration token in
  # /etc/github-runner-kya-sr.token (0600, created on the VPS; refresh with:
  #   gh api -X POST repos/s52ai/kya-group/actions/runners/registration-token --jq .token).
  services.github-runners.kya-sr = {
    enable = true;
    name = "kya-sr-vps";
    url = "https://github.com/s52ai/kya-group";
    tokenFile = "/etc/github-runner-kya-sr.token";
    extraLabels = [ "kya-sr" ];
    replace = true;
    extraPackages = with pkgs; [ git openssh ];
  };

  virtualisation.oci-containers.containers.kya-sr-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/kya-sr/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/kya-sr-postgres.env" ];
    extraOptions = [ "--network=kya-sr-net" "--memory=512m" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kya-sr 0755 root root -"
    "d /var/lib/kya-sr/postgres 0700 999 999 -"
  ];

  systemd.services.kya-sr-network = {
    description = "Create KYA sales-reporting podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-kya-sr-postgres.service"
      "kya-sr-migrate.service"
      "kya-sr.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create kya-sr-net --ignore";
    };
  };

  systemd.services.kya-sr-migrate = {
    description = "KYA sales-reporting DB migrate + bootstrap admin";
    after = [ "podman-kya-sr-postgres.service" "kya-sr-network.service" ];
    requires = [ "podman-kya-sr-postgres.service" "kya-sr-network.service" ];
    before = [ "kya-sr.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      PODMAN=${pkgs.podman}/bin/podman
      for _ in $(seq 1 60); do
        if $PODMAN exec kya-sr-postgres pg_isready -U kya -d sales_reporting >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done
      $PODMAN run --rm --network=kya-sr-net --env-file /etc/kya-sr.env \
        localhost/kya-sales-reporting:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/migrate.ts
      $PODMAN run --rm --network=kya-sr-net --env-file /etc/kya-sr.env \
        localhost/kya-sales-reporting:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/bootstrap-admin.ts
    '';
  };

  systemd.services.kya-sr = {
    description = "KYA sales-reporting app";
    after = [ "kya-sr-migrate.service" "kya-sr-network.service" ];
    requires = [ "kya-sr-migrate.service" "kya-sr-network.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-sr";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-sr \
          --network=kya-sr-net \
          -p 127.0.0.1:3002:3002 \
          --env-file /etc/kya-sr.env \
          localhost/kya-sales-reporting:latest
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-sr";
    };
  };

  # Served at kya-sr.stynx.app (Cloudflare DNS → A record to 72.62.125.38,
  # DNS-only/grey-cloud so ACME HTTP-01 reaches the origin).
  services.nginx.virtualHosts."kya-sr.stynx.app" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3002";
      proxyWebsockets = true;
    };
  };
}
