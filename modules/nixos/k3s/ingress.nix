{ config, lib, pkgs, acmeEmail, ... }:
let
  cfg = config.services.k3s;
in
{
  config = lib.mkIf cfg.enable {
    # nginx-ingress-controller via k3s HelmChart CRD
    environment.etc."rancher/k3s/server/manifests/nginx-ingress.yaml".text = ''
      apiVersion: v1
      kind: Namespace
      metadata:
        name: ingress-nginx
      ---
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: ingress-nginx
        namespace: kube-system
      spec:
        repo: https://kubernetes.github.io/ingress-nginx
        chart: ingress-nginx
        version: 4.11.3
        targetNamespace: ingress-nginx
        valuesContent: |-
          controller:
            kind: DaemonSet
            hostPort:
              enabled: true
            service:
              type: ClusterIP
            ingressClassResource:
              default: true
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                cpu: 500m
                memory: 512Mi
            config:
              proxy-body-size: "100m"
              proxy-buffer-size: "16k"
              ssl-redirect: "true"
              use-forwarded-headers: "true"
    '';

    # cert-manager for Let's Encrypt SSL
    environment.etc."rancher/k3s/server/manifests/cert-manager.yaml".text = ''
      apiVersion: v1
      kind: Namespace
      metadata:
        name: cert-manager
      ---
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: cert-manager
        namespace: kube-system
      spec:
        repo: https://charts.jetstack.io
        chart: cert-manager
        version: v1.16.2
        targetNamespace: cert-manager
        valuesContent: |-
          crds:
            enabled: true
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
    '';

    # ClusterIssuer for Let's Encrypt (applied after cert-manager is ready)
    environment.etc."rancher/k3s/server/manifests/cluster-issuer.yaml".text = ''
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          server: https://acme-v02.api.letsencrypt.org/directory
          email: ${acmeEmail}
          privateKeySecretRef:
            name: letsencrypt-prod-account
          solvers:
          - http01:
              ingress:
                class: nginx
      ---
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-staging
      spec:
        acme:
          server: https://acme-staging-v02.api.letsencrypt.org/directory
          email: ${acmeEmail}
          privateKeySecretRef:
            name: letsencrypt-staging-account
          solvers:
          - http01:
              ingress:
                class: nginx
    '';
  };
}
