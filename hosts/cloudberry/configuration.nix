#
# this machine is the Internet router
# it does bridging, vlans, routing, failover, vpn
#
{ flake, inputs, pkgs, ... }: {
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
    flake.nixosModules.server-backup

    ./router.nix
    ./ddns.nix
    ./http
    ./unifi.nix
    ./proxies.nix
    ./wan-status.nix
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
        # TOPTON 4-port
        # Intel(R) Celeron(R) N5105 @ 2.00GHz

        # powersave / balanced / performance
        governor = "powersave";

        # never / auto / always
        turbo = "never";
      };
    };
  };

  services.server-backup = {
    enable = true;
    paths = [ "/var/lib" ];
  };

  zramSwap.enable = true;

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = true; # TODO: enable ipv6
  };

  environment.systemPackages = with pkgs; [
    speedtest-cli
    iperf
    # https://iperf.fr/iperf-servers.php
    # iperf -c speedtest.serverius.net -p 5002
  ];

  services.iperf3.enable = true;
}
