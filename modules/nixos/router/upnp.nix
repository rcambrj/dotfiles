{ config, lib, pkgs, ... }:
with config.router;
with lib;
{
  options = {};
  config = {
    services.miniupnpd = {
      enable = false; # TODO: enable this with logic to switch the externalInterface based on wan-failover
      upnp = true;
      natpmp = true;
      internalIPs = [ networks.lan.ifname ];
      externalInterface = networks.wan.ifname;
    };

    systemd.services.miniupnpd = {
      serviceConfig = {
        Restart = "always";
      };
    };
  };
}