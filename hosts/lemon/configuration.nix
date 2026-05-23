{ config, flake, inputs, lib, modulesPath, pkgs, perSystem, ... }: {
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"

    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.disko-standard
    flake.nixosModules.common
    flake.nixosModules.cloud-vps
    flake.nixosModules.tailscale
    flake.nixosModules.server-backup
    ./http
  ];

  networking.hostName = "lemon";
  nixpkgs.hostPlatform = "aarch64-linux";
  disko.devices.disk.disk1.device = "/dev/sda";

  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;
  services.resolved = {
    enable = true;
    settings.Resolve = {
      LLMNR = false;
      MulticastDNS = false;
    }
  };
  systemd.network.networks = {
    "10-wired" = {
      matchConfig.Name = "e*";
      dhcpV4Config.UseDNS = "no";
      dhcpV6Config.UseDNS = "no";
      networkConfig = {
        LinkLocalAddressing = "no";
        MulticastDNS = "no";
        LLMNR = "no";
        DHCP = "yes";
      };
    };
  };

  services.server-backup = {
    enable = false;
    paths = [
      # nothing to back up
    ];
  };
}