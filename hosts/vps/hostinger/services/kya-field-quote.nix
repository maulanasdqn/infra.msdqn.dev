{ pkgs, ... }:
{
  # KYA field-quote — self-hosted on the VPS (migrated off DigitalOcean App
  # Platform). The app image is built ON the VPS from /opt/kya-group via
  # apps/field-quote/Dockerfile and tagged localhost/kya-field-quote:latest
  # (see `kya-fq-build` in the deploy notes). A dedicated Postgres 17 lives in
  # a container on a private podman network. Secrets are read from env files
  # created on the VPS (0600), mirroring the glitchtip/n8n pattern:
  #   /etc/kya-fq-postgres.env  POSTGRES_USER/PASSWORD/DB
  #   /etc/kya-fq.env           DATABASE_URL, BETTER_AUTH_*, WEB_ORIGIN, admin bootstrap

  virtualisation.oci-containers.containers.kya-fq-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/kya-fq/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/kya-fq-postgres.env" ];
    extraOptions = [ "--network=kya-fq-net" "--memory=512m" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kya-fq 0755 root root -"
    "d /var/lib/kya-fq/postgres 0700 999 999 -"
  ];

  # Private podman network so the app resolves the DB by container name.
  systemd.services.kya-fq-network = {
    description = "Create KYA field-quote podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-kya-fq-postgres.service"
      "kya-fq-migrate.service"
      "kya-fq.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create kya-fq-net --ignore";
    };
  };

  # Drizzle migrations + admin bootstrap, once Postgres is accepting connections
  # and before the app comes up. Idempotent (safe to re-run on every deploy).
  systemd.services.kya-fq-migrate = {
    description = "KYA field-quote DB migrate + bootstrap admin";
    after = [ "podman-kya-fq-postgres.service" "kya-fq-network.service" ];
    requires = [ "podman-kya-fq-postgres.service" "kya-fq-network.service" ];
    before = [ "kya-fq.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      PODMAN=${pkgs.podman}/bin/podman
      # Wait for Postgres to accept connections.
      for _ in $(seq 1 60); do
        if $PODMAN exec kya-fq-postgres pg_isready -U kya -d field_quote >/dev/null 2>&1; then
          break
        fi
        sleep 2
      done
      $PODMAN run --rm --network=kya-fq-net --env-file /etc/kya-fq.env \
        localhost/kya-field-quote:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/migrate.ts
      $PODMAN run --rm --network=kya-fq-net --env-file /etc/kya-fq.env \
        localhost/kya-field-quote:latest \
        /app/api/node_modules/.bin/tsx /app/api/src/bootstrap-admin.ts
    '';
  };

  # The app itself. Custom podman-run unit (not oci-containers) because the
  # image is a locally-built localhost/ tag that must never be pulled.
  systemd.services.kya-fq = {
    description = "KYA field-quote app";
    after = [ "kya-fq-migrate.service" "kya-fq-network.service" ];
    requires = [ "kya-fq-migrate.service" "kya-fq-network.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 120;
      ExecStartPre = "-${pkgs.podman}/bin/podman rm -f kya-fq";
      ExecStart = ''
        ${pkgs.podman}/bin/podman run --rm --name kya-fq \
          --network=kya-fq-net \
          -p 127.0.0.1:3003:3003 \
          --env-file /etc/kya-fq.env \
          localhost/kya-field-quote:latest
      '';
      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 kya-fq";
    };
  };

  # Served at kya-fq.stynx.app (Cloudflare DNS → A record to 72.62.125.38,
  # DNS-only/grey-cloud so ACME HTTP-01 reaches the origin).
  services.nginx.virtualHosts."kya-fq.stynx.app" = {
    enableACME = true;
    forceSSL = true;
    extraConfig = "client_max_body_size 25m;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:3003";
      proxyWebsockets = true;
    };
  };
}
