#
# this machine is a kubernetes node
#
{ flake, inputs, ... }: {
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
    inputs.agenix-template.nixosModules.default

    flake.nixosModules.access-server
    flake.nixosModules.bare-metal
    flake.nixosModules.base
    flake.nixosModules.common
    flake.nixosModules.config-intel
    flake.nixosModules.disk-aio
    flake.nixosModules.disk-savers
    flake.nixosModules.gpu-intel
    flake.nixosModules.kubernetes-manifests
    flake.nixosModules.kubernetes-node
    flake.nixosModules.telemetry
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
    };
    networks."11-enp2s0" = {
      matchConfig.Name = "enp2s0";
      networkConfig.Bridge = "br0";
    };
    networks."11-enp3s0" = {
      matchConfig.Name = "enp3s0";
      networkConfig.Bridge = "br0";
    };
    networks."11-enp4s0" = {
      matchConfig.Name = "enp4s0";
      networkConfig.Bridge = "br0";
    };
    networks."12-br0" = {
      matchConfig.Name = "br0";
      networkConfig.DHCP = "ipv4";
      networkConfig.LinkLocalAddressing = "no";
      dhcpV4Config.UseHostname = "no";
      linkConfig.RequiredForOnline = "yes";
      routingPolicyRules = [{
        # this helps to prevent VPN rules/routes affecting SSH while debugging
        Priority = 100;
        To = "192.168.142.0/24";
      }];
      # bypass local nameserver setting so that DNS requests will go through VPN
      dhcpV4Config.UseDNS = "no";
    };
  };
  services.resolved = {
    enable = true;
    extraConfig = ''
    [Resolve]
    DNS=192.168.142.1
    Domains=~cambridge.me
    '';
  };

  services.kubernetes-node = {
    enable = true;
    role = "server";
    strategy = "init";
  };
  services.kubernetes-manifests.enable = true;
  disk-savers.etcd-store = {
    targetDir = "/var/lib/rancher/k3s/server/db/etcd/member";
    targetMountName = "var-lib-rancher-k3s-server-db-etcd-member";
    diskDir = "/var/lib/etcd-store";
    syncEvery = "6h";
  };
}
