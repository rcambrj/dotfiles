{ config, inputs, lib, pkgs, ... }: with lib; {
  imports = [
    inputs.self.nixosModules.netbird
  ];

  services.netbird = {
    # this option is a noop WRT nixos firewall because that's disabled
    # but for correctness, override the default "client" value
    useRoutingFeatures = mkForce "server";

    clients.default = {
      # not using systemd-resolved, and dnsmasq needs 53
      dns-resolver.port = 5053;
    };
  };
}
