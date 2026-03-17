{ pkgs, ... }:
let
  fluentbitConfig = pkgs.writeText "fluent-bit.conf" ''
    [SERVICE]
        flush        5
        daemon       off
        log_level    info
        parsers_file ${pkgs.fluent-bit}/etc/fluent-bit/parsers.conf

    [INPUT]
        name             tail
        path             /var/log/syslog,/var/log/messages
        tag              syslog
        read_from_head   true
        skip_empty_lines on

    [INPUT]
        name             tail
        path             /var/log/auth.log,/var/log/secure
        tag              auth
        read_from_head   true
        skip_empty_lines on

    [INPUT]
        name             tail
        path             /var/log/kern.log
        tag              kernel
        read_from_head   true
        skip_empty_lines on

    [INPUT]
        name             systemd
        tag              systemd.*
        read_from_tail   on

    [INPUT]
        name             tail
        path             /var/log/suricata/eve.json
        tag              suricata
        read_from_head   false
        skip_empty_lines on
        parser           json

    [INPUT]
        name             tail
        path             /var/log/nginx/access.log
        tag              nginx.access
        read_from_head   false
        skip_empty_lines on

    [INPUT]
        name             tail
        path             /var/log/nginx/error.log
        tag              nginx.error
        read_from_head   false
        skip_empty_lines on

    [INPUT]
        name             tail
        path             /var/log/fail2ban.log
        tag              fail2ban
        read_from_head   false
        skip_empty_lines on

    [INPUT]
        name             tail
        path             /var/log/audit/audit.log
        tag              audit
        read_from_head   false
        skip_empty_lines on

    [OUTPUT]
        name             http
        match            *
        host             103.31.205.209
        port             443
        uri              /api/v1/ingest/agent
        format           json_stream
        json_date_key    @timestamp
        json_date_format iso8601
        tls              on
        tls.verify       off
        header           Host ingest-aysiem.msdqn.dev
        header           X-Node-Id 019ceabb-b183-79b2-8622-2bb6652af6dc
        header           X-Node-Hostname msdqn
  '';
in
{
  systemd.services.fluent-bit = {
    description = "Fluent Bit - AYSIEM Agent";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.fluent-bit}/bin/fluent-bit -c ${fluentbitConfig}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
