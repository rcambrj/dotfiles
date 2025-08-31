{ config, lib, ... }:
with config.router;
with lib;
{
  services.miniupnpd = {
    enable = true;
    upnp = true;
    natpmp = true;
    internalIPs = [ home-netdev ];
    externalInterface = wan-netdev;
  };

  systemd.services.miniupnpd = {
    serviceConfig = {
      Restart = "always";
    };
  };
}