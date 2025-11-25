{ config, lib, pkgs, ... }:
with lib;
{
  imports = [
    ./dnsmasq.nix
    ./firewall.nix
    ./forwarding.nix
    ./interfaces.nix
    ./pppd.nix
    ./sqm-ifb-redirect.nix
    ./uplink-primary.nix
    ./uplink-secondary.nix
    ./upnp.nix
  ];

  options.router = mkOption {
    # TODO: make options structure more strict once changes slow down
  };

  config = {};
}