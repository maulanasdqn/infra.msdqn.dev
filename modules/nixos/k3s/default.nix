{ config, lib, pkgs, ... }:
let
  cfg = config.services.k3s;
in
{
  imports = [
    ./storage.nix
    ./ingress.nix
    ./secrets.nix
  ];

  config = lib.mkIf cfg.enable {
    # Required kernel modules for k3s
    boot.kernelModules = [
      "br_netfilter"
      "overlay"
      "ip_vs"
      "ip_vs_rr"
      "ip_vs_wrr"
      "ip_vs_sh"
      "iptable_nat"
      "iptable_filter"
    ];

    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.ipv4.ip_forward" = 1;
    };

    # k3s server configuration
    services.k3s = {
      extraFlags = lib.mkDefault (toString [
        "--disable=traefik"
        "--disable=servicelb"
        "--write-kubeconfig-mode=644"
        "--flannel-backend=vxlan"
        "--cluster-cidr=10.42.0.0/16"
        "--service-cidr=10.43.0.0/16"
        "--cluster-dns=10.43.0.10"
        "--kubelet-arg=system-reserved=cpu=200m,memory=256Mi"
        "--kubelet-arg=kube-reserved=cpu=200m,memory=256Mi"
        "--kubelet-arg=eviction-hard=memory.available<100Mi,nodefs.available<10%"
      ]);
    };

    # Firewall rules for k3s
    networking.firewall = {
      allowedTCPPorts = [
        6443   # Kubernetes API
        10250  # Kubelet metrics
        2379   # etcd (for future HA)
        2380   # etcd peer (for future HA)
      ];
      allowedUDPPorts = [
        8472   # Flannel VXLAN
      ];
      # Allow pod and service network traffic
      trustedInterfaces = [ "cni0" "flannel.1" ];
    };

    # Install kubectl and helm
    environment.systemPackages = with pkgs; [
      kubectl
      kubernetes-helm
      k9s
    ];

    # Set KUBECONFIG for root
    environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

    # Alias for convenience
    environment.shellAliases = {
      k = "kubectl";
    };
  };
}
