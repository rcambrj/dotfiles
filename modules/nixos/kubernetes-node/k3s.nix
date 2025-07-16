{ config, pkgs, ... }: {
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--disable=traefik"
    ];
    # https://docs.k3s.io/cli/token
    tokenFile = config.age.secrets.k3s-token.path;

    # https://docs.k3s.io/datastore/ha-embedded#existing-single-node-clusters
    clusterInit = true;

    # points to all kubernetes nodes
    # serverAddr = "kubernetes.cambridge.me";
  };
}