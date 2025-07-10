{ config, ... }: {
  networking.firewall = {
      # https://docs.k3s.io/installation/requirements#networking
    allowedTCPPorts = [
      6443      # apiserver
      2379 2380 # etcd
    ];
    allowedUDPPorts = [
      8472      # flannel
    ];
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      # "--disable=traefik"
    ];
    # https://docs.k3s.io/cli/token
    tokenFile = config.age.secrets.k3s-token.path;

    # https://docs.k3s.io/datastore/ha-embedded#existing-single-node-clusters
    # clusterInit = true;
  };
}