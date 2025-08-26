{ config, ... }:
with config.router;
{
  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network = {
    # create vlan netdevs (make one per vlan on each port)
    # netdevs."10-vlan-wan" = {
    #   Kind = "vlan";
    #   Name = "wan";
    #   vlanConfig.Id = wan-vlan;
    # };
    netdevs."10-vlan-lte" = {
      netdevConfig = {
        Kind = "vlan";
        Name = lte-netdev;
      };
      vlanConfig.Id = lte-vlan;
    };
    netdevs."10-vlan-home" = {
      netdevConfig = {
        Kind = "vlan";
        Name = "home-trunk";
      };
      vlanConfig.Id = home-vlan;
    };
    netdevs."10-vlan-mgmt" = {
      netdevConfig = {
        Kind = "vlan";
        Name = "mgmt-trunk";
      };
      vlanConfig.Id = mgmt-vlan;
    };

    # attach vlan networks to ports
    # networks."20-vlan-wan" = {
    #   matchConfig = {
    #     Name = ifaces.wan;
    #     Type = "ether";
    #   };
    #   networkConfig.VLAN = [ "wan" ];
    # };
    networks."20-vlan-trunk" = {
      matchConfig = {
        Name = ifaces.sw0;
        Type = "ether";
      };
      networkConfig.VLAN = [ "home-trunk" "mgmt-trunk" lte-netdev ];
    };

    # create bridge netdevs
    netdevs."30-bridge-home" = {
      netdevConfig = {
        Kind = "bridge";
        Name = home-netdev;
      };
    };
    netdevs."30-bridge-mgmt" = {
      netdevConfig = {
        Kind = "bridge";
        Name = mgmt-netdev;
      };
    };

    # attach vlans/ports to bridges
    networks."40-bridge-home-trunk" = {
      matchConfig = {
        Type = "vlan";
        Name = "home-trunk";
      };
      networkConfig.Bridge = home-netdev;
    };
    networks."40-bridge-home-0" = {
      matchConfig = {
        Type = "ether";
        Name = ifaces.home-0;
      };
      networkConfig.Bridge = home-netdev;
    };
    networks."40-bridge-mgmt-trunk" = {
      matchConfig = {
        Type = "vlan";
        Name = "mgmt-trunk";
      };
      networkConfig.Bridge = mgmt-netdev;
    };

    # configure networks
    networks."50-home-config" = {
      matchConfig.Name = home-netdev;
      networkConfig = {
        Address = home-cidr;
        ConfigureWithoutCarrier = true;
        IPv4Forwarding = true;
        IPv6Forwarding = false; # deal with this challenge another day
      };
      routingPolicyRules = [{
        Priority = 100;
        To = home-cidr;
      }];
    };

    networks."50-mgmt-config" = {
      matchConfig.Name = mgmt-netdev;
      networkConfig = {
        Address = mgmt-cidr;
        ConfigureWithoutCarrier = true;
        IPv4Forwarding = true;
        IPv6Forwarding = false; # deal with this challenge another day
      };
      routingPolicyRules = [{
        Priority = 100;
        To = mgmt-cidr;
      }];
    };

    networks."50-lte-config" = {
      matchConfig = {
        Type = "vlan";
        Name = lte-netdev;
      };
      networkConfig = {
        DHCP = "yes";
      };
    };

    networks."50-wan-config-tmp" = {
      # temporarily do plain DHCP onto the existing network during development
      matchConfig = {
        Type = "ether";
        Name = wan-vlan;
      };
      networkConfig = {
        DHCP = "yes";
      };
    };
  };
}