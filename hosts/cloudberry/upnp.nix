{ config, lib, ... }:
with config.router;
with lib;
{
  services.miniupnpd = {
    enable = true;
    upnp = true;
    natpmp = true;
    internalIPs = [ networks.lan.ip ];
    externalInterface = networks.wan.ifname;
  };

  systemd.services.miniupnpd = {
    serviceConfig = {
      Restart = "always";
    };
  };
}