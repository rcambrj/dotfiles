{ inputs, pkgs, ... }:
with pkgs.lib;
let
  primary-prefix = "10.11.0";
  primary-gateway = "${primary-prefix}.1";
  router-config = (import ./test-router.nix) { inherit primary-gateway; };
  secondary-gateway = router-config.networks.secondary.ip4-gateway;
  secondary-adjacent = "${router-config.networks.secondary.ip4-prefix}.100";
  common-address = "10.55.0.1";

  useBase = cfg: recursiveUpdate cfg {
    networking.useDHCP = false;
    services.resolved.enable = false;
    systemd.network.enable = true;
    networking.useNetworkd = true;

    # don't care for opening ports on test machines, but need iptables
    networking.firewall.enable = true;
    networking.firewall.trustedInterfaces = [ "+" ];
  };
in
pkgs.testers.runNixOSTest {
  name = "router";
  nodes = {
    primary_gw = { pkgs, ... }: let
      ifname = "enp1s0";
    in useBase {
      virtualisation.interfaces = {
        "${ifname}".vlan = 1;
      };
      systemd.network.networks."10-downlink" = {
        matchConfig.Name = ifname;
        networkConfig = {
          Address = [
            # to test traffic on the chosen network route
            "${common-address}/24"
            # to test traffic to the gateway
            "${primary-gateway}/24"
          ];
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
      services.static-web-server = {
        enable = true;
        root = pkgs.writeTextDir "index.html" "dst=primary";
      };
    };

    secondary_gw = { pkgs, ... }: let
      ifname = "enp1s0";
    in useBase {
      virtualisation.interfaces = {
        ${ifname}.vlan = 2;
      };
      systemd.network.netdevs."10-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan";
        };
        vlanConfig.Id = router-config.networks.secondary.vlan;
      };
      systemd.network.networks."10-vlan" = {
        matchConfig.Name = ifname;
        networkConfig.VLAN = "vlan";
      };
      systemd.network.networks."10-downlink" = {
        matchConfig.Name = "vlan";
        networkConfig = {
          Address = [
            # to test traffic on the chosen network route
            "${common-address}/24"
            # to test traffic to the gateway
            "${secondary-gateway}/24"
            # to test traffic to an address other than the gateway (simulates data usage)
            "${secondary-adjacent}/24"
          ];
          ConfigureWithoutCarrier = true;
        };
      };
      services.static-web-server = {
        enable = true;
        root = pkgs.writeTextDir "index.html" "dst=secondary";
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

    primary_gw.wait_for_unit('dnsmasq')
    secondary_gw.wait_for_unit('multi-user.target')

    # uplink is primary_gw
    router.wait_until_succeeds('systemctl show up-or-down-uplink-failover | grep StatusText= | grep state=UP', 30)

    # ping the primary gateway
    router.wait_until_succeeds('ping -c 1 -I br-primary ${primary-gateway}', 10)

    # ping the secondary gateway
    router.wait_until_succeeds('ping -c 1 -I br-secondary ${secondary-gateway}', 10)

    # curl the secondary gateway dashboard
    router.succeed('curl -vis --interface br-secondary http://${secondary-gateway}:8787')

    # traffic to elsewhere on the secondary uplink
    # ping should succeed to anywhere
    # other traffic must be blocked
    router.succeed('ping -c 1 -I br-secondary ${secondary-adjacent}')
    router.fail('curl -vis --interface br-secondary http://${secondary-adjacent}:8787')

    # traffic without a specified interface should go through primary (and hit primary_gw)
    router.succeed('curl -vis http://${common-address}:8787 | grep "dst=primary"')

    # stop primary_gw responses (simulate offline)
    primary_gw.succeed('iptables -A OUTPUT -j DROP')
    router.wait_until_succeeds('systemctl show up-or-down-uplink-failover | grep StatusText= | grep state=DOWN', 10)

    # traffic without a specified interface should go through secondary (and hit secondary_gw)
    router.succeed('curl -vis http://${common-address}:8787 | grep "dst=secondary"')

    # restart primary_gw responses (simulate online)
    primary_gw.succeed('iptables -D OUTPUT -j DROP')
    router.wait_until_succeeds('systemctl show up-or-down-uplink-failover | grep StatusText= | grep state=UP', 10)

    # traffic without a specified interface should go through primary (and hit primary_gw)
    router.succeed('curl -vis http://${common-address}:8787 | grep "dst=primary"')
  '';
}