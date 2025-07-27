{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.kubernetes-node;
in {
  options.services.kubernetes-node = {
    enable = mkEnableOption "Start a kubernetes node on this host";
    role = mkOption {
      type = types.enum [ "server" "agent" ];
      default = "agent";
    };
    strategy = mkOption {
      type = types.enum [ "init" "join" "reset" ];
      description = ''
        How to configure k3s regarding an existing cluster:
        * init: initialises a new cluster
        * join: joins this node to the cluster
        * reset: makes this node forget any joins
      '';
      default = "join";
    };
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
      tokenFile = config.age.secrets.k3s-token.path;
      role = cfg.role;
      extraFlags = (
        []
        ++ (optionals (cfg.role == "server") [
          "--disable=traefik"
          "--tls-san=kubernetes.cambridge.me"
          "--flannel-backend=wireguard-native"
        ])
        ++ (optional (cfg.strategy == "init") "--cluster-init")
        ++ (optional (cfg.strategy == "reset") "--cluster-reset")
      );
    } // (optionalAttrs (cfg.strategy == "join") {
      serverAddr = "https://kubernetes.cambridge.me:6443";
    });
  };
}