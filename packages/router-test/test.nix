{ inputs, pkgs, ... }:
with pkgs.lib;
let
  test-router = (import ./test-router.nix) { inherit primary-gateway; };

  primary-prefix = "10.11.0";
  primary-gateway = "${primary-prefix}.1";
  secondary-gateway = test-router.networks.secondary.ip4-gateway;
  secondary-adjacent = "${test-router.networks.secondary.ip4-prefix}.100";
  common-gateway = "10.55.0.1";

  router-lan0 = test-router.networks.lan0.ip4-address;
  client0 = "${test-router.networks.lan0.ip4-prefix}.10";
  client1 = "${test-router.networks.lan0.ip4-prefix}.11";

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
            "${common-gateway}/24"
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
        vlanConfig.Id = test-router.networks.secondary.vlan;
      };
      systemd.network.networks."10-vlan" = {
        matchConfig.Name = ifname;
        networkConfig = {
          LinkLocalAddressing = "no";
          VLAN = "vlan";
        };
      };
      systemd.network.networks."10-downlink" = {
        matchConfig.Name = "vlan";
        networkConfig = {
          Address = [
            # to test traffic on the chosen network route
            "${common-gateway}/24"
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

    router = { pkgs, ... }: {
      imports = [
        inputs.self.nixosModules.router
      ];
      virtualisation.interfaces = {
        "${test-router.ifaces.primary}".vlan    = 1;
        "${test-router.ifaces.vlan-trunk}".vlan = 2;
        "${test-router.ifaces.lan-0}".vlan      = 3;
      };
      router = test-router;
    };

    client0 = { pkgs, ... }: let
      ifname = "enp1s0";
    in useBase {
      networking.hostName = "client0";
      virtualisation.interfaces = {
        ${ifname}.vlan = 3;
      };
      systemd.network.networks."10-lan0" = {
        matchConfig.Name = ifname;
        networkConfig = {
          DHCP = "yes";
          Address = "${client0}/24";
        };
      };
    };

    client1 = { pkgs, ... }: let
      ifname = "enp1s0";
    in useBase {
      networking.hostName = "client1";
      virtualisation.interfaces = {
        ${ifname}.vlan = 2;
      };
      systemd.network.netdevs."10-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan";
        };
        vlanConfig.Id = test-router.networks.lan0.vlan;
      };
      systemd.network.networks."10-vlan" = {
        matchConfig.Name = ifname;
        networkConfig = {
          LinkLocalAddressing = "no";
          VLAN = "vlan";
        };
      };
      systemd.network.networks."10-lan0" = {
        matchConfig.Name = "vlan";
        networkConfig = {
          DHCP = "yes";
          Address = "${client1}/24";
        };
      };
    };
  };

  testScript = ''
    start_all()

    # uplink is primary_gw
    router.wait_until_succeeds('systemctl show up-or-down-uplink-failover | grep StatusText= | grep state=UP', 30)

    # ping the primary gateway
    router.wait_until_succeeds('ping -c 1 -I br-primary ${primary-gateway}', 10)

    # ping the secondary gateway
    router.wait_until_succeeds('ping -c 1 -I br-secondary ${secondary-gateway}', 10)

    #########################################
    ##               OUTPUT                ##
    #########################################

    # curl the secondary gateway dashboard
    router.succeed('curl -m 2 -vis --interface br-secondary http://${secondary-gateway}:8787')

    # traffic to elsewhere on the secondary uplink
    # ping should succeed to anywhere
    # other traffic must be blocked
    router.succeed('ping -c 1 -I br-secondary ${secondary-adjacent}')
    router.fail('curl -m 2 -vis --interface br-secondary http://${secondary-adjacent}:8787')

    # traffic without a specified interface should go through primary uplink
    router.succeed('curl -m 2 -vis http://${common-gateway}:8787 | grep "dst=primary"')

    # simulate primary uplink offline
    primary_gw.succeed('iptables -t raw -A PREROUTING -j DROP')
    router.wait_until_succeeds('systemctl show up-or-down-uplink-failover | grep StatusText= | grep state=DOWN', 10)

    # traffic without a specified interface should go through secondary uplink
    router.succeed('curl -m 2 -vis http://${common-gateway}:8787 | grep "dst=secondary"')

    # simulate primary uplink online
    primary_gw.succeed('iptables -t raw -D PREROUTING -j DROP')
    router.wait_until_succeeds('systemctl show up-or-down-uplink-failover | grep StatusText= | grep state=UP', 10)

    # traffic without a specified interface should go through primary uplink
    router.succeed('curl -m 2 -vis http://${common-gateway}:8787 | grep "dst=primary"')

    #########################################
    ##               BRIDGE                ##
    #########################################

    # traffic between clients on a bridge (untagged <> tagged vlan)
    client0.wait_until_succeeds('ping -c 1 ${router-lan0}', 10)
    client0.wait_until_succeeds('ping -c 1 ${client1}', 10)
    client1.wait_until_succeeds('ping -c 1 ${router-lan0}', 10)
    client1.wait_until_succeeds('ping -c 1 ${client0}', 10)

    print(client0.succeed('ip -br a && ip rule && ip ro show table all'))

    #########################################
    ##               FORWARD               ##
    #########################################

    # traffic forwarded through the router should go through primary uplink
    client0.succeed('curl -m 2 -vis http://${common-gateway}:8787 | grep "dst=primary"')

    # simulate primary uplink offline
    primary_gw.succeed('iptables -t raw -A PREROUTING -j DROP')
    router.wait_until_succeeds('systemctl show up-or-down-uplink-failover | grep StatusText= | grep state=DOWN', 10)

    # traffic forwarded through the router should go through secondary uplink
    client0.succeed('curl -m 2 -vis http://${common-gateway}:8787 | grep "dst=secondary"')

    # simulate primary uplink online
    primary_gw.succeed('iptables -t raw -D PREROUTING -j DROP')
    router.wait_until_succeeds('systemctl show up-or-down-uplink-failover | grep StatusText= | grep state=UP', 10)

    # traffic forwarded through the router should go through primary uplink
    client0.succeed('curl -m 2 -vis http://${common-gateway}:8787 | grep "dst=primary"')
  '';
}