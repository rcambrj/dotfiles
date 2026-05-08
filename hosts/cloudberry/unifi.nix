{ config, inputs, lib, pkgs, ... }:
with lib;
{
  imports = [
    inputs.unifi-os-server.nixosModules.unifi-os-server
  ];

  services.unifi-os-server = {
    enable = true;
    uosSystemIP = config.router.networks.mgmt.ip4-address;
  };

  services.nginx.virtualHosts."unifi.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "https://127.0.0.1:${toString config.services.unifi-os-server.ports.ui}";
      extraConfig = ''
        proxy_ssl_verify off;
      '';
    };
  };
}