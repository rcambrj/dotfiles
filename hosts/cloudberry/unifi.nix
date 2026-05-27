{ config, inputs, lib, pkgs, ... }:
with lib;
{
  imports = [
    inputs.unifi-os-server.nixosModules.unifi-os-server
  ];

  services.unifi-os-server = {
    enable = true;
    uosSystemIP = config.router.networks.mgmt.ip4-address;
    # The container inherits /etc/resolv.conf=127.0.0.1 from the host, which
    # is useless inside its netns. Point it at the host's dnsmasq via the LAN
    # address instead.
    extraOptions = [
      "--dns=${config.router.networks.lan.ip4-address}"
    ];
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