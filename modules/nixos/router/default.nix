{ config, lib, pkgs, ... }:
with lib;
{
  imports = [
    ./dnsmasq.nix
    ./firewall.nix
    ./forwarding.nix
    ./interfaces.nix
    ./pppd.nix
    ./uplink-failover.nix
    ./upnp.nix
  ];

  options.router = mkOption {
    # TODO: make options structure more strict once changes slow down
  };

  config = {};
}