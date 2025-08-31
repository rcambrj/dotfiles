#
# this machine is the Internet router
# it does bridging, vlans, routing, failover, vpn
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
    flake.nixosModules.netbird

    ./vars.nix
    ./dnsmasq.nix
    ./interfaces.nix
    ./firewall.nix
    ./upnp.nix
    ./wan-failover.nix
    ./ddns.nix
    ./http
    ./unifi.nix
  ];

  networking.hostName = "cloudberry";

  fileSystems = {
    "/var/lib" = {
      device = "/dev/disk/by-label/NIXOSSTATE";
      fsType = "ext4";
      # neededForBoot = true;
    };
  };

  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        # Dell Wyse 3040
        # Intel(R) Atom(TM) x5-Z8350  CPU @ 1.44GHz

        # powersave / balanced / performance
        governor = "performance";

        # never / auto / always
        turbo = "auto";
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

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = true; # deal with this challenge another day
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };
}
