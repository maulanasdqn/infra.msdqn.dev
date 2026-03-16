{ pkgs, ... }:
let
  wazuhVersion = "4.9.2";

  wazuhAgentUnpacked = pkgs.stdenv.mkDerivation {
    pname = "wazuh-agent-unpacked";
    version = wazuhVersion;

    src = pkgs.fetchurl {
      url = "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_${wazuhVersion}-1_amd64.deb";
      hash = "sha256-9X2MoKGakLYj3pNfiqsYQ0s357lStJ6MQnFOAWxhYPI=";
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = "dpkg-deb -x $src .";

    installPhase = ''
      mkdir -p $out
      cp -r var/ossec/* $out/
      # Fix shebang in scripts
      for f in $out/bin/*; do
        if head -1 "$f" 2>/dev/null | grep -q '#!/bin/sh'; then
          substituteInPlace "$f" --replace-quiet '#!/bin/sh' '#!${pkgs.bash}/bin/bash'
        fi
        if head -1 "$f" 2>/dev/null | grep -q '#!/bin/bash'; then
          substituteInPlace "$f" --replace-quiet '#!/bin/bash' '#!${pkgs.bash}/bin/bash'
        fi
      done
    '';
  };

  # FHS wrapper so glibc-linked binaries work on NixOS
  wazuhFHS = pkgs.buildFHSEnv {
    name = "wazuh-agentd";
    targetPkgs = pkgs: with pkgs; [
      glibc
      openssl
      zlib
      pcre2
      systemd
      gcc.cc.lib
      audit
    ];
    runScript = "/var/ossec/bin/wazuh-agentd";
  };

  wazuhControl = pkgs.buildFHSEnv {
    name = "wazuh-control";
    targetPkgs = pkgs: with pkgs; [
      glibc
      openssl
      zlib
      pcre2
      systemd
      gcc.cc.lib
      bash
      coreutils
      procps
      gnugrep
      gnused
      gawk
      audit
    ];
    runScript = "${pkgs.bash}/bin/bash";
  };

  ossecConf = pkgs.writeText "ossec.conf" ''
    <ossec_config>
      <client>
        <server>
          <address>103.31.205.209</address>
          <port>31514</port>
          <protocol>tcp</protocol>
        </server>
        <enrollment>
          <enabled>yes</enabled>
          <manager_address>103.31.205.209</manager_address>
          <port>31515</port>
        </enrollment>
      </client>

      <client_buffer>
        <disabled>no</disabled>
        <queue_size>5000</queue_size>
        <events_per_second>500</events_per_second>
      </client_buffer>

      <!-- File integrity monitoring -->
      <syscheck>
        <frequency>600</frequency>
        <directories check_all="yes" realtime="yes">/etc</directories>
        <directories check_all="yes" realtime="yes">/usr/bin</directories>
        <directories check_all="yes" realtime="yes">/usr/sbin</directories>
        <directories check_all="yes">/boot</directories>
        <ignore>/etc/mtab</ignore>
        <ignore>/etc/hosts.deny</ignore>
        <ignore>/etc/adjtime</ignore>
        <ignore>/etc/resolv.conf</ignore>
      </syscheck>

      <!-- Rootcheck -->
      <rootcheck>
        <disabled>no</disabled>
        <frequency>43200</frequency>
      </rootcheck>

      <!-- Log analysis -->
      <localfile>
        <log_format>syslog</log_format>
        <location>/var/log/auth.log</location>
      </localfile>

      <localfile>
        <log_format>syslog</log_format>
        <location>/var/log/syslog</location>
      </localfile>

      <localfile>
        <log_format>audit</log_format>
        <location>/var/log/audit/audit.log</location>
      </localfile>

      <localfile>
        <log_format>syslog</log_format>
        <location>/var/log/nginx/error.log</location>
      </localfile>

      <localfile>
        <log_format>syslog</log_format>
        <location>/var/log/nginx/access.log</location>
      </localfile>

      <!-- Suricata IDS EVE JSON -->
      <localfile>
        <log_format>json</log_format>
        <location>/var/log/suricata/eve.json</location>
      </localfile>

      <!-- Fail2ban -->
      <localfile>
        <log_format>syslog</log_format>
        <location>/var/log/fail2ban.log</location>
      </localfile>

      <!-- Active response -->
      <active-response>
        <disabled>no</disabled>
      </active-response>
    </ossec_config>
  '';
in
{
  users.users.wazuh = {
    isSystemUser = true;
    group = "wazuh";
    home = "/var/ossec";
  };
  users.groups.wazuh = {};

  systemd.services.wazuh-agent = {
    description = "Wazuh Agent";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.bash pkgs.coreutils pkgs.procps pkgs.gnugrep pkgs.gnused pkgs.gawk ];

    preStart = ''
      # Set up /var/ossec directory structure
      mkdir -p /var/ossec/{etc,logs,queue,var,tmp,wodles,active-response}
      mkdir -p /var/ossec/etc/shared
      mkdir -p /var/ossec/queue/{alerts,diff,fim,ossec,rids,sockets}
      mkdir -p /var/ossec/logs/{ossec,alerts}
      mkdir -p /var/ossec/var/run
      mkdir -p /var/ossec/active-response/bin

      # Install agent files from nix store
      cp -rf ${wazuhAgentUnpacked}/bin /var/ossec/
      cp -rf ${wazuhAgentUnpacked}/lib /var/ossec/
      cp -rf ${wazuhAgentUnpacked}/ruleset /var/ossec/ 2>/dev/null || true
      cp -rf ${wazuhAgentUnpacked}/wodles /var/ossec/ 2>/dev/null || true
      cp -f ${wazuhAgentUnpacked}/etc/internal_options.conf /var/ossec/etc/ 2>/dev/null || true
      cp -f ${wazuhAgentUnpacked}/etc/local_internal_options.conf /var/ossec/etc/ 2>/dev/null || true
      cp -rf ${wazuhAgentUnpacked}/etc/shared/* /var/ossec/etc/shared/ 2>/dev/null || true

      # Always update config from nix
      cp -f ${ossecConf} /var/ossec/etc/ossec.conf

      # Set permissions
      chown -R wazuh:wazuh /var/ossec
      chmod -R 750 /var/ossec
      chmod 640 /var/ossec/etc/ossec.conf
    '';

    script = ''
      exec ${wazuhControl}/bin/wazuh-control -c '/var/ossec/bin/wazuh-control start && sleep infinity'
    '';

    serviceConfig = {
      Type = "simple";
      ExecStop = "${wazuhControl}/bin/wazuh-control -c '/var/ossec/bin/wazuh-control stop'";
      Restart = "on-failure";
      RestartSec = "10s";
      KillMode = "control-group";
    };
  };

  # Provide wazuh-control for manual management
  environment.systemPackages = [ wazuhControl ];
}
