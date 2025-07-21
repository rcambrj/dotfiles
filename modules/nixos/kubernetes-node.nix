{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.kubernetes-node;
in {
  options.services.kubernetes-node = {
    enable = mkEnableOption "Start a kubernetes node on this host";
  };

  config = mkIf cfg.enable {
    age.secrets.k3s-token.file = ../../secrets/k3s-token.age;

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
      # comment this to bring up the first node
      # serverAddr = "kubernetes.cambridge.me";
    };

    # Longhorn is installed onto kubernetes via ArgoCD
    # these are the host-level dependencies
    environment.systemPackages = with pkgs; [ tgt ];
    services.openiscsi = {
      enable = true;
      name = config.networking.hostName;
    };
    services.nfs.server.enable = true;
    systemd.services.iscsid.serviceConfig.PrivateMounts = "yes";

    # Fix Longhorn expecting FHS
    # https://github.com/longhorn/longhorn/issues/2166
    # https://takingnotes.net/kubernetes/longhorn/
    system.activationScripts.usrlocalbin = ''
      mkdir -m 0755 -p /usr/local
      ln -nsf /run/current-system/sw/bin /usr/local/
    '';
  };
}