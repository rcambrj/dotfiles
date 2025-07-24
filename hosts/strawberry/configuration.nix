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
    flake.nixosModules.disk-aio
    flake.nixosModules.common
    flake.nixosModules.bare-metal
    flake.nixosModules.config-intel
    flake.nixosModules.gpu-intel
    flake.nixosModules.telemetry
    flake.nixosModules.kubernetes-node
    flake.nixosModules.kubernetes-manifests
    flake.nixosModules.disk-savers
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
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network = {
    networks = {
      "10-wired" = {
        matchConfig.Name = "e*";
        networkConfig = {
          DHCP = "yes";
        };
      };
    };
  };

  # Dell Wyse 3040 doesn't have much RAM, but it does have 8GB internal MMC
  swapDevices = [
    {
      device = "/dev/mmcblk0p1";
    }
  ];
  zramSwap.enable = true;

  services.kubernetes-node.enable = true;
  # services.kubernetes-manifests.enable = true;
  disk-savers.etcd-store = {
    targetDir = "/var/lib/rancher/k3s/server/db/etcd/member";
    targetMountName = "var-lib-rancher-k3s-server-db-etcd-member";
    diskDir = "/var/lib/etcd-store";
    syncEvery = "6h";
  };
}
