{ config, inputs, lib, pkgs, ... }: with lib; {
  imports = [
    inputs.self.nixosModules.netbird
  ];

  services.netbird.clients.default = {
    dns-resolver.port = 5053; # not using systemd-resolved, and dnsmasq needs 53
  };
}
