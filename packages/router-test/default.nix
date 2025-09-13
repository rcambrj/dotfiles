{ inputs, pkgs, ... }:
with pkgs.lib;
let
  wan-prefix = "10.11.0";
  wan-gateway = "${wan-prefix}.1";
  router-config = (import ./router-config.nix) { inherit wan-gateway; };
in
pkgs.testers.runNixOSTest {
  name = "router";
  nodes = {
    wan_gateway = { pkgs, ... }: let
      ifname = "enp1s0";
    in {
      virtualisation.interfaces = {
        "${ifname}".vlan = 1;
      };
      networking.firewall.enable = false;
      systemd.network.enable = true;
      services.resolved.enable = false;
      networking.useDHCP = false;
      networking.useNetworkd = true;
      systemd.network.networks."10-downlink" = {
        matchConfig.Name = ifname;
        networkConfig = {
          Address = "${wan-gateway}/24";
          ConfigureWithoutCarrier = true;
        };
      };
      services.dnsmasq = {
        enable = true;
        settings = {
          interface = ifname;
          dhcp-range = "${ifname},${wan-prefix}.101,${wan-prefix}.254";
        };
      };
    };

    lte_gateway = { pkgs, ... }: let
      ifname = "enp1s0";
    in {
      virtualisation.interfaces = {
        ${ifname}.vlan = 2;
      };
      networking.firewall.enable = false;
      systemd.network.enable = true;
      services.resolved.enable = false;
      networking.useDHCP = false;
      networking.useNetworkd = true;
      systemd.network.netdevs."10-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan";
        };
        vlanConfig.Id = router-config.networks.lte.vlan;
      };
      systemd.network.networks."10-vlan" = {
        matchConfig.Name = ifname;
        networkConfig = {
          VLAN = "vlan";
        };
      };
      systemd.network.networks."10-downlink" = {
        matchConfig.Name = "vlan";
        networkConfig = {
          Address = [
            # to test traffic to the modem
            "${router-config.networks.lte.ip4-gateway}/24"
            # to test traffic to an address other than the modem (simulates data usage)
            "${router-config.networks.lte.ip4-prefix}.100/24"
          ];
          ConfigureWithoutCarrier = true;
        };
      };
    };

    router = { pkgs, ... }: ({
      imports = [
        inputs.self.nixosModules.router
      ];
      virtualisation.interfaces = {
        "${router-config.ifaces.wan}".vlan        = 1;
        "${router-config.ifaces.vlan-trunk}".vlan = 2;
        "${router-config.ifaces.lan-0}".vlan      = 3;
      };
      router = router-config;
    });
  };

  testScript = ''
    start_all()

    wan_gateway.wait_for_unit("dnsmasq")

    lte_gateway.wait_for_unit("multi-user.target")
    print(lte_gateway.execute("ip -br a"))

    router.wait_until_succeeds("ping -c 1 -I br-wan 10.11.0.1", 10)

    router.wait_until_succeeds("ping -c 1 -I br-lte ${router-config.networks.lte.ip4-gateway}", 10)

  '';
}