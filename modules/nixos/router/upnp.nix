{ config, lib, pkgs, ... }:
with config.router;
with lib;
{
  options = {};
  config = {
    services.miniupnpd = {
      enable = true;
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