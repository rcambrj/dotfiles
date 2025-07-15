#
# this machine is a kubernetes node
#
{ flake, inputs, modulesPath, ... }: {
  imports = [
    # TODO: https://github.com/numtide/nixos-facter/issues/125
    # inputs.nixos-facter-modules.nixosModules.facter
    # { config.facter.reportPath = ./facter.json; }
    "${toString modulesPath}/profiles/all-hardware.nix"

    inputs.agenix-template.nixosModules.default
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.disk-split
    flake.nixosModules.common
    flake.nixosModules.bare-metal
    flake.nixosModules.config-intel

    # ./backup.nix
    # ./gpu.nix
    # ./telemetry.nix
    # ./kubernetes
  ];

  networking.hostName = "strawberry";

  disko.devices.disk.disk1.device = "/dev/disk/by-id/usb-JMicron_PCIe_DD0000000000001D-0:0";
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
        # governor = "powersave";
        # energy_performance_preference = "power";
        # turbo = "never";

        governor = "performance";
        energy_performance_preference = "performance";
        turbo = "auto";
      };
    };
  };

  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;
}
