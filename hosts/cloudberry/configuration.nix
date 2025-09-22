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

    # https://iperf.fr/iperf-servers.php
    # iperf -c speedtest.serverius.net -p 5002
    iperf

    (writeShellScriptBin "networkd-leases" ''
      # https://askubuntu.com/a/1506644
      # TODO: some hardware addresses come out garbled
      if=$1
      link_id="$(${iproute2}/bin/ip --oneline link show dev "$if" | cut -f 1 -d:)";
      ${systemd}/bin/busctl --system -j get-property org.freedesktop.network1 \
        "/org/freedesktop/network1/link/''${link_id}" \
        org.freedesktop.network1.DHCPServer \
        Leases \
      | ${jq}/bin/jq -r 'def bytehex:
              [(./16|floor), .%16] | map(if . < 10 then 48 + . else . + 87 end) | implode;
          def formatentry:
              (.[2]|map(tostring)|join(".")) as $ip | (.[1][1:]|map(bytehex)|join(":")) as $mac | "\($ip) \($mac)";
          .data[] | formatentry'
    '')
  ];

  services.iperf3.enable = true;
}
