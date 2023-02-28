{ ... }: {
  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;

  # systemd.network = {
  #   # bridge netdevs
  #   netdevs."10-br-lan".netdevConfig = {
  #     Kind = "bridge";
  #     Name = "br-lan";
  #     MACAddress = "00:e2:69:59:2e:76";
  #   };
  #   netdevs."10-br-mgmt".netdevConfig = {
  #     Kind = "bridge";
  #     Name = "br-lan";
  #     MACAddress = "00:e2:69:59:2e:76";
  #   };

  #   # vlan netdevs
  #   netdevs."20-enp1s0-6"   = {
  #     # KPN uplink requires VLAN 6
  #     matchConfig = {
  #       Name = "enp1s0-6";
  #       Kind = "vlan";
  #     };
  #     netdevConfig = {};
  #     vlanConfig.Id = 6;
  #   };
  #   netdevs."20-enp1s0-44" = {
  #     # LTE 4G
  #     matchConfig = {
  #       Name = "enp1s0-142";
  #       Kind = "vlan";
  #     };
  #     netdevConfig = {};
  #     vlanConfig.Id = 142;
  #   };
  #   netdevs."20-enp1s0-142" = {
  #     # Primary LAN
  #     matchConfig = {
  #       Name = "enp1s0-142";
  #       Kind = "vlan";
  #     };
  #     netdevConfig = {};
  #     vlanConfig.Id = 142;
  #   };

  #   # physical networks
  #   networks."30-enp1s0" = {
  #     # 00:e2:69:59:2e:72
  #     matchConfig.Name = "enp1s0";
  #     networkConfig.VLAN = [ "enp1s0-6" ];
  #   };
  #   networks."30-enp2s0" = {
  #     # 00:e2:69:59:2e:73
  #     matchConfig.Name = "enp2s0";
  #     networkConfig.VLAN = [ "enp1s0-44" "enp1s0-142" ];
  #   };
  #   networks."30-enp3s0" = {
  #     # 00:e2:69:59:2e:74
  #     matchConfig.Name = "enp3s0";
  #     networkConfig.Bridge = "br-lan";
  #   };
  #   networks."30-enp4s0" = {
  #     # 00:e2:69:59:2e:75
  #     matchConfig.Name = "enp4s0";
  #     networkConfig.Bridge = "br-lan";
  #   };

  #   # vlan networks
  #   networks."40-enp1s0-6" = {
  #     matchConfig = {
  #       Name = "enp1s0-6";
  #       Type = "vlan";
  #     };
  #   };
  #   networks."40-enp2s0-44" = {
  #     matchConfig = {
  #       Name = "enp2s0-44";
  #       Type = "vlan";
  #     };
  #   };
  #   networks."40-enp2s0-142" = {
  #     matchConfig = {
  #       Name = "enp2s0-142";
  #       Type = "vlan";
  #     };
  #   };

  #   # bridge networks
  #   networks."50-br-lan" = {
  #     matchConfig.Name = "br-lan";
  #     linkConfig = {
  #       RequiredForOnline = "yes";
  #     };
  #     networkConfig = {
  #       Address = "192.168.142.1/24";
  #       IPv4Forwarding = "yes";
  #       # IPv6Forwarding = "yes";
  #       DHCPServer = "yes";
  #     };
  #     dhcpServerConfig = {

  #     };
  #     routingPolicyRules = [{
  #       Priority = 100;
  #       To = "192.168.142.0/24";
  #     }];
  #   };
  # };
}