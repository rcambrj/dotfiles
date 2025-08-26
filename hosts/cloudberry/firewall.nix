{ config, lib, ... }:
with config.router;
with lib;
{
  networking.firewall.trustedInterfaces = [
    home-netdev
    mgmt-netdev
  ];
}