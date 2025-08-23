{ config, lib, pkgs, ... }: with builtins; with lib; let
  nodes = [
    "cranberry.cambridge.me"
    "blueberry.cambridge.me"
    "orange.cambridge.me"
  ];

  cfg = config.services.kubernetes-node;
  serverFlags = [
    "--disable=traefik"
    "--disable=servicelb"
    "--flannel-backend=wireguard-native"
    "--tls-san=home.cambridge.me"
  ] ++ (map (node: "--tls-san=${node}") nodes);
in {
  options.services.kubernetes-node = {
    enable = mkEnableOption "Start a kubernetes node on this host";
    role = mkOption {
      type = types.enum [ "server" "agent" ];
      default = "agent";
    };
    openFirewallOnInterface = mkOption {
      type = types.str;
      default = "";
      description = "If specified, only open ports on this interface. Otherwise, open ports on all interfaces";
    };
    k3sExtraFlags = mkOption {
      description = "Extra flags to pass to the k3s command. Don't modify services.k3s.extraFlags directly if you want k3s-reset and k3s-init to be consistent with these flags";
      type = with lib.types; either str (listOf str);
      default = [ ];
    };
    k3s-reset = mkOption {
      readOnly = true;
      default = pkgs.writeShellScriptBin "k3s-reset" ''
        ${pkgs.k3s}/bin/k3s server \
          --cluster-reset \
          --token-file ${config.age.secrets.k3s-token.path} \
          ${builtins.concatStringsSep " " serverFlags} \
          ${builtins.concatStringsSep " " cfg.k3sExtraFlags}
      '';
    };
    k3s-init = mkOption {
      readOnly = true;
      default = pkgs.writeShellScriptBin "k3s-init" ''
        ${pkgs.k3s}/bin/k3s server \
          --cluster-init \
          --token-file ${config.age.secrets.k3s-token.path} \
          ${builtins.concatStringsSep " " serverFlags} \
          ${builtins.concatStringsSep " " cfg.k3sExtraFlags}
      '';
    };
  };

  config = mkIf cfg.enable {
    age.secrets.k3s-token.file = ../../secrets/k3s-token.age;

    networking.firewall = let
      ports = {
        # https://docs.k3s.io/installation/requirements#networking
        allowedTCPPorts = [
          6443      # apiserver
          2379 2380 # etcd
          80 443    # ingress-nginx
          10250     # kubelet
          7946      # metallb
        ];
        allowedUDPPorts = [
          8472      # flannel
          7946      # metallb
        ];
      };
    in (if (stringLength cfg.openFirewallOnInterface > 0) then {
      interfaces."${cfg.openFirewallOnInterface}" = ports;
    } else ports);

    services.k3s = {
      enable = true;
      tokenFile = config.age.secrets.k3s-token.path;
      role = cfg.role;
      serverAddr = "https://127.0.0.1:7443";
      extraFlags = (
        []
        ++ (optionals (cfg.role == "server") serverFlags)
        ++ cfg.k3sExtraFlags
      );
    };

    environment.systemPackages = [ cfg.k3s-reset cfg.k3s-init ];

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