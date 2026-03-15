{ pkgs, ... }:
let
  heartbeatScript = pkgs.writeShellScript "aysiem-heartbeat" ''
    export PATH="${pkgs.lib.makeBinPath [ pkgs.curl pkgs.systemd pkgs.gawk pkgs.gnused pkgs.coreutils pkgs.jq ]}:$PATH"

    API_URL="https://api-aysiem.msdqn.dev"
    TOKEN="e0e86e2c-f3b5-4452-9b2f-f5cc4d240090"

    OS_INFO=""
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      OS_INFO="$PRETTY_NAME"
    fi

    SERVICES="[]"
    if command -v systemctl &>/dev/null; then
      SERVICES=$(systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null \
        | awk '{print $1}' \
        | sed 's/\.service$//' \
        | head -50 \
        | jq -Rn '[inputs | {name: ., service_type: "systemd", status: "running"}]' 2>/dev/null || echo "[]")
    fi

    PAYLOAD=$(jq -n --arg os "$OS_INFO" --argjson svcs "$SERVICES" '{os_info: $os, services: $svcs}')

    curl -sf -X POST "$API_URL/api/v1/inventory/heartbeat" \
      -H "Content-Type: application/json" \
      -H "X-Integration-Token: $TOKEN" \
      -d "$PAYLOAD" >/dev/null 2>&1 || true
  '';
in
{
  systemd.services.aysiem-heartbeat = {
    description = "AYSIEM heartbeat agent";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = heartbeatScript;
    };
  };

  systemd.timers.aysiem-heartbeat = {
    description = "AYSIEM heartbeat timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "60s";
      Persistent = true;
    };
  };
}
