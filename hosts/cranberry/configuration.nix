#
# this machine is a kubernetes node
#
{ config, flake, inputs, lib, pkgs, ... }: with lib; {
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
    inputs.agenix-template.nixosModules.default

    flake.nixosModules.access-server
    flake.nixosModules.bare-metal
    flake.nixosModules.base
    flake.nixosModules.common
    flake.nixosModules.config-intel
    flake.nixosModules.disko-node
    flake.nixosModules.gpu-intel
    flake.nixosModules.telemetry

    ./node.nix
  ];

  networking.hostName = "cranberry";

  disko.devices.disk.disk1.device = "/dev/disk/by-id/ata-Vi550_S3_SSD_493535208372024";
  fileSystems = {
    "/var/lib" = {
      device = "/dev/disk/by-label/NIXOSSTATE";
      fsType = "ext4";
      neededForBoot = true;
    };
  };

  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        # Intel(R) Celeron(R) N5105 @ 2.00GHz

        # powersave / balanced / performance
        governor = "performance";

        # power / performance
        # energy_performance_preference = "power";

        # never / auto / always
        turbo = "auto";
      };
    };
  };

  systemd.network.enable = true;
  systemd.network.wait-online.enable = mkForce true;
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network = {
    # TOPTON 4-port bridge
    netdevs."10-br0".netdevConfig = {
      Kind = "bridge";
      Name = "br0";
      MACAddress = "a6:99:b0:72:64:7e";
    };
    networks."11-enp1s0" = {
      matchConfig.Name = "enp1s0";
      networkConfig.Bridge = "br0";
      linkConfig.RequiredForOnline = "no";
    };
    networks."11-enp2s0" = {
      matchConfig.Name = "enp2s0";
      networkConfig.Bridge = "br0";
      linkConfig.RequiredForOnline = "no";
    };
    networks."11-enp3s0" = {
      matchConfig.Name = "enp3s0";
      networkConfig.Bridge = "br0";
      linkConfig.RequiredForOnline = "no";
    };
    networks."11-enp4s0" = {
      matchConfig.Name = "enp4s0";
      networkConfig.Bridge = "br0";
      linkConfig.RequiredForOnline = "no";
    };
    networks."12-br0" = {
      matchConfig.Name = "br0";
      networkConfig.DHCP = "ipv4";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = "routable";
      dhcpV4Config.UseHostname = "no"; # Could not set hostname: Access denied
    };
  };
}
