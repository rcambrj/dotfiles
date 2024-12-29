#
# this machine is the Internet access
# * bridging, vlans, routing
# * vpn
# * unifi-controller
#
{ flake, inputs, ... }: {
  imports = [
    # inputs.nixos-facter-modules.nixosModules.facter
    # { config.facter.reportPath = ./facter.json; }
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.bare-metal-usb
    flake.nixosModules.config-intel
    flake.lib.template
    ./interfaces.nix
  ];

  networking.hostName = "cloudberry";

  age.secrets = {
    # todo
  };

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
        governor = "powersave";
        energy_performance_preference = "power";
        turbo = "never";
        # Intel(R) Celeron(R) N5105 @ 2.00GHz
        # https://askubuntu.com/a/1064309/1682130
      };
    };
  };
}
