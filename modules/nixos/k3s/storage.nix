{ config, lib, pkgs, ... }:
let
  cfg = config.services.k3s;
in
{
  config = lib.mkIf cfg.enable {
    # Create persistent storage directories for k3s workloads
    systemd.tmpfiles.rules = [
      "d /var/lib/k3s-storage 0755 root root -"
      "d /var/lib/k3s-storage/postgresql 0700 999 999 -"
      "d /var/lib/k3s-storage/minio 0755 root root -"
      "d /var/lib/k3s-storage/n8n 0755 1000 1000 -"
      "d /var/lib/k3s-storage/uptime-kuma 0755 root root -"
      "d /var/lib/k3s-storage/glitchtip 0755 root root -"
      "d /var/lib/k3s-storage/roundcube 0755 root root -"
    ];

    # Local-path-provisioner manifest (auto-deployed by k3s)
    environment.etc."rancher/k3s/server/manifests/local-path-config.yaml".text = ''
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: local-path-config
        namespace: kube-system
      data:
        config.json: |-
          {
            "nodePathMap": [
              {
                "node": "DEFAULT_PATH_FOR_NON_LISTED_NODES",
                "paths": ["/var/lib/k3s-storage"]
              }
            ]
          }
    '';
  };
}
