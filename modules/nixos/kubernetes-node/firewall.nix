{ config, pkgs, ... }: {
  networking.firewall = {
      # https://docs.k3s.io/installation/requirements#networking
    allowedTCPPorts = [
      6443      # apiserver
      2379 2380 # etcd
      80 443    # ingress-nginx
    ];
    allowedUDPPorts = [
      8472      # flannel
    ];
  };
}