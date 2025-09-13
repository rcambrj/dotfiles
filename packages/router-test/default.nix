{ inputs, pkgs, ... }:
with pkgs.lib;
let
  primary-prefix = "10.11.0";
  primary-gateway = "${primary-prefix}.1";
  router-config = (import ./router-config.nix) { inherit primary-gateway; };
  webserver = {
    services.static-web-server = {
      enable = true;
      root = pkgs.writeText "index.html" ''Hello World!'';
    };
  };
in
pkgs.testers.runNixOSTest {
  name = "router";
  nodes = {
    primary_gw = { pkgs, ... }: let
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
          Address = "${primary-gateway}/24";
          ConfigureWithoutCarrier = true;
        };
      };
      services.dnsmasq = {
        enable = true;
        settings = {
          interface = ifname;
          dhcp-range = "${ifname},${primary-prefix}.101,${primary-prefix}.254";
        };
      };
    };

    secondary_gw = { pkgs, ... }: let
      ifname = "enp1s0";
    in webserver // {
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
        vlanConfig.Id = router-config.networks.secondary.vlan;
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
            "${router-config.networks.secondary.ip4-gateway}/24"
            # to test traffic to an address other than the modem (simulates data usage)
            "${router-config.networks.secondary.ip4-prefix}.100/24"
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
        "${router-config.ifaces.primary}".vlan    = 1;
        "${router-config.ifaces.vlan-trunk}".vlan = 2;
        "${router-config.ifaces.lan-0}".vlan      = 3;
      };
      router = router-config;
    });
  };

  testScript = ''
    start_all()

    primary_gw.wait_for_unit("dnsmasq")

    secondary_gw.wait_for_unit("multi-user.target")
    print(secondary_gw.execute("ip -br a"))

    # test traffic to the primary gateway
    router.wait_until_succeeds("ping -c 1 -I br-primary 10.11.0.1", 10)
    # test traffic to the secondary gateway
    router.wait_until_succeeds("ping -c 1 -I br-secondary ${router-config.networks.secondary.ip4-gateway}", 10)
    # test traffic to elsewhere on the secondary uplink (blocked)
    router.succeed("curl --interface br-secondary http://${router-config.networks.secondary.ip4-gateway}:8787")
    router.fail("curl --interface br-secondary http://${router-config.networks.secondary.ip4-prefix}.100:8787")

  '';
}