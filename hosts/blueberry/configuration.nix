#
# this machine is a kubernetes node
#
{ flake, inputs, lib, ... }: with lib; {
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
    flake.nixosModules.server-backup
    flake.nixosModules.telemetry

    ./primary-wan.nix
    ./node.nix
  ];

  networking.hostName = "blueberry";

  disko.devices.disk.disk1.device = "/dev/disk/by-id/ata-PNY_1TB_SATA_SSD_PNB17255012860100073";
  fileSystems = {
    "/var/lib" = {
      device = "/dev/disk/by-label/NIXOSSTATE";
      fsType = "ext4";
      neededForBoot = true;
    };
  };

  services.mbpfan.enable = true;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        # Mac Mini 2011
        # Intel Core i7 @ 2.0GHz

        # powersave / balanced / performance
        governor = "powersave";

        # never / auto / always
        turbo = "never";
      };
    };
  };

  services.server-backup.enable = true;

  systemd.network.enable = true;
  systemd.network.wait-online.enable = mkForce true; # so gluster volume doesnt mount too early
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks = {
    "10-disable-enp2s0f0" = {
      # the built-in network port is fried
      matchConfig.Name = "enp2s0f0";
      linkConfig.Unmanaged = "yes";
    };
    "20-wired" = {
      matchConfig.Name = "e*";
      networkConfig.DHCP = "yes";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
