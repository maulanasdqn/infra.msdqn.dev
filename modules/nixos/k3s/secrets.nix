{ config, lib, pkgs, ... }:
let
  cfg = config.services.k3s;
in
{
  config = lib.mkIf cfg.enable {
    # sops-secrets-operator for Kubernetes secrets management
    # Uses the same age keys as sops-nix
    environment.etc."rancher/k3s/server/manifests/sops-secrets-operator.yaml".text = ''
      apiVersion: v1
      kind: Namespace
      metadata:
        name: sops-system
      ---
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: sops-secrets-operator
        namespace: kube-system
      spec:
        repo: https://isindir.github.io/sops-secrets-operator/
        chart: sops-secrets-operator
        version: 0.18.5
        targetNamespace: sops-system
        valuesContent: |-
          secretsAsFiles:
            - name: sops-age-key
              mountPath: /etc/sops-age-key
              secretName: sops-age-key
          envVars:
            - name: SOPS_AGE_KEY_FILE
              value: /etc/sops-age-key/key.txt
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 128Mi
    '';

    # Systemd service to create the age key secret in k8s
    systemd.services.k3s-sops-key-setup = {
      description = "Setup SOPS age key for k3s";
      after = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.kubectl ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "30s";
      };
      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        # Wait for k3s API to be ready
        for i in $(seq 1 60); do
          if kubectl get nodes &>/dev/null; then
            break
          fi
          echo "Waiting for k3s API... ($i/60)"
          sleep 5
        done

        # Create sops-system namespace if not exists
        kubectl create namespace sops-system --dry-run=client -o yaml | kubectl apply -f -

        # Create age key secret from sops-nix generated key
        if [ -f /var/lib/sops-nix/key.txt ]; then
          kubectl create secret generic sops-age-key \
            --from-file=key.txt=/var/lib/sops-nix/key.txt \
            --namespace sops-system \
            --dry-run=client -o yaml | kubectl apply -f -
          echo "SOPS age key secret created"
        else
          echo "Warning: /var/lib/sops-nix/key.txt not found, sops-secrets-operator may not work"
        fi
      '';
    };
  };
}
