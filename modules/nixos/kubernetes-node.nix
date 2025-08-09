{ config, lib, pkgs, ... }: with lib; let
  nodes = [
    "cranberry.cambridge.me"
    "strawberry.cambridge.me"
    "blueberry.cambridge.me"
  ];

  cfg = config.services.kubernetes-node;
  serverFlags = [
    "--disable=traefik"
    "--tls-san=kubernetes.cambridge.me"
    "--flannel-backend=wireguard-native"
  ];
  k3s-reset = pkgs.writeShellScriptBin "k3s-reset" ''
    ${pkgs.k3s}/bin/k3s server \
      --cluster-reset \
      --token-file ${config.age.secrets.k3s-token.path} \
      ${builtins.concatStringsSep " " serverFlags}
  '';
  k3s-init = pkgs.writeShellScriptBin "k3s-init" ''
    ${pkgs.k3s}/bin/k3s server \
      --cluster-init \
      --token-file ${config.age.secrets.k3s-token.path} \
      ${builtins.concatStringsSep " " serverFlags}
  '';
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
    k3s-reset = mkOption {
      readOnly = true;
      default = k3s-reset;
    };
    k3s-init = mkOption {
      readOnly = true;
      default = k3s-init;
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
        10250     # kubelet
        7443      # poor man's load balancer
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
        ++ (optionals (cfg.role == "server") serverFlags)
        ++ (optional (cfg.strategy == "init") "--cluster-init")
        ++ (optional (cfg.strategy == "reset") "--cluster-reset")
      );
    } // (optionalAttrs (cfg.strategy == "join") {
      serverAddr = "https://127.0.0.1:7443";
    });

    environment.systemPackages = [ k3s-reset k3s-init ];

    services.nginx = {
      # poor man's load balancer (requires no separate machine)
      # each node checks all other nodes to see which one it can join
      # this ensures a joining node can eventually find a running node
      enable = true;
      streamConfig = let
        upstreamServers = lib.concatMapStringsSep "\n" (node: "  server ${node}:6443;") nodes;
      in ''
        upstream k3s_servers {
          ${upstreamServers}
        }

        server {
          listen 7443 so_keepalive=on;
          proxy_pass k3s_servers;

          # Improve LB behavior
          proxy_timeout 1s;
          proxy_connect_timeout 1s;
        }
      '';
    };

  };
}