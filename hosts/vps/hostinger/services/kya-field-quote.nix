{ pkgs, ... }:
let

  kyaCiDeploy = pkgs.writeShellScript "kya-fq-ci-deploy" ''
    set -euo pipefail
    umask 077
    rm -rf /opt/kya-group
    mkdir -p /opt/kya-group
    ${pkgs.gnutar}/bin/tar -xf - -C /opt/kya-group
    cd /opt/kya-group
    ${pkgs.podman}/bin/podman build --net=host \
      -f apps/field-quote/Dockerfile -t localhost/kya-field-quote:latest .
    # Apply DB migrations + bootstrap with the freshly-built image BEFORE rolling
    # the app. restart re-runs the oneshot and blocks on it — a failed migration
    # aborts here (set -e) and leaves the old app running.
    ${pkgs.systemd}/bin/systemctl restart kya-fq-migrate.service
    ${pkgs.systemd}/bin/systemctl restart kya-fq.service
    for _ in $(seq 1 45); do
      if ${pkgs.curl}/bin/curl -sf http://127.0.0.1:3003/healthz >/dev/null 2>&1; then
        ${pkgs.podman}/bin/podman image prune -f >/dev/null 2>&1 || true
        echo "kya-fq deploy OK"
        exit 0
      fi
      sleep 2
    done
    echo "kya-fq healthcheck failed after restart" >&2
    exit 1
  '';
in
{

  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${kyaCiDeploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCO3MNbnYv2drZtsFt1c1Z4ytDoIhAKGjiLdB/h3CQG kya-fq-ci-deploy''
  ];

  services.github-runners.kya-fq = {
    enable = true;
    name = "kya-fq-vps";
    url = "https://github.com/s52ai/kya-group";
    tokenFile = "/etc/github-runner-kya.token";
    extraLabels = [ "kya-fq" ];
    replace = true;
    extraPackages = with pkgs; [ git openssh ];
  };

  virtualisation.oci-containers.containers.kya-fq-postgres = {
    image = "postgres:17-alpine";
    volumes = [ "/var/lib/kya-fq/postgres:/var/lib/postgresql/data" ];
    environmentFiles = [ "/etc/kya-fq-postgres.env" ];
    extraOptions = [ "--network=kya-fq-net" "--memory=512m" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kya-fq 0755 root root -"
    "d /var/lib/kya-fq/postgres 0700 70 70 -"
  ];

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
