{ config, lib, pkgs, ... }:
with config.router;
with lib;
let
  base = {
    # [Network]
    LinkLocalAddressing = "ipv6";
    EmitLLDP = "no";
    LLDP = "no";
    IPv6SendRA = "no"; # use dnsmasq instead
  };
  noipv6 = {
    # [Network]
    LinkLocalAddressing = "no";
    IPv6AcceptRA = "no";
  };
  noipv4 = {
    # [Network]
    DHCP = "no";
  };
  noip = noipv6 // noipv4;
in {
  options = {};
  config = {
    systemd.network.enable = true;
    networking.useDHCP = false;
    networking.useNetworkd = true;

    systemd.network = {
      config = {
        # these aliases are not used programmatically
        # just nice-to-haves for monitoring/debugging
        routeTables = concatMapAttrs (networkName: network:
          optionalAttrs ((network.rt or "") != "") { "${networkName}" = network.rt; }
        ) networks;
      };

      #
      # processes config.router.networks into something meaningful for networkd.
      # for simplicity, every network gets its own bridge network interface.
      # this likely has a performance impact on networks with just one port.
      # but it's probably marginal.
      #

      netdevs = concatMapAttrs (networkName: network: {}
        # netdevs for tagged vlans
        // listToAttrs (map (iface: nameValuePair "10-${iface}-${networkName}" {
          netdevConfig = {
            Kind = "vlan";
            Name = "${iface}-${toString network.vlan}";
          };
          vlanConfig.Id = network.vlan;
        }) network.ifaces.t)

        # netdevs for bridges
        // {
          "20-br-${networkName}" = {
            netdevConfig = {
              Kind = "bridge";
              Name = "br-${networkName}";
              MACAddress = network.mac;
            };
          };
        }
      ) networks;

      networks = {}
        # attach vlans to physical ports
        // (concatMapAttrs (ifaceFriendly: iface: let
          vlans = attrValues (mapAttrs (networkName: network: network.vlan) (filterAttrs (networkName: network: elem iface network.ifaces.t) networks));
        in optionalAttrs (length vlans > 0) {
          "10-${iface}" = {
            matchConfig = {
              Name = iface;
              Type = "ether";
            };
            networkConfig = base // noip // {
              VLAN = map (vlan: "${iface}-${toString vlan}") vlans;
            };
          };
        }) ifaces)

        # attach networks to bridges
        // (concatMapAttrs (networkName: network: {}
          # tagged vlans
          // listToAttrs (map (iface: nameValuePair "20-${iface}-${networkName}" {
            matchConfig = {
              Type = "vlan";
              Name = "${iface}-${toString network.vlan}";
            };
            networkConfig.Bridge = "br-${networkName}";
          }) (network.ifaces.t or []))

          # untagged ports
          // listToAttrs (map (iface: nameValuePair "30-${iface}" {
            matchConfig = {
              Type = "ether";
              Name = iface;
            };
            networkConfig.Bridge = "br-${networkName}";
          }) (network.ifaces.u or []))
        ) networks)

        # configure bridges
        // (concatMapAttrs (networkName: network: {
          "40-${"br-${networkName}"}" = {
            dhcp-uplink = {
              matchConfig = {
                Type = "bridge";
                Name = "br-${networkName}";
              };
              networkConfig = base // noipv6 // {
                DHCP = "yes";
              };
              dhcpV4Config = {
                UseHostname = "no"; # Could not set hostname: Access denied
                RouteTable = network.rt;
                SendHostname = "no";
              };
              routingPolicyRules = [
                {
                  Priority = network.prio;
                  Table = network.rt;
                }
              ];
              # dhcpV6Config = {}; # TODO
            };
            pppoe-uplink = {
              matchConfig = {
                Type = "bridge";
                Name = "br-${networkName}";
              };
              networkConfig = base // noip;
              routingPolicyRules = [
                {
                  Family = "both";
                  Priority = network.prio;
                  Table = network.rt;
                }
              ];
            };
            static-uplink = {
              matchConfig = {
                Type = "bridge";
                Name = "br-${networkName}";
              };
              networkConfig = base // noipv6 // {
                Address = network.ip4-cidr;
              };
              routes = [{
                Gateway = network.ip4-gateway;
                PreferredSource = network.ip4-address;
                Table = network.rt;
              }];
              routingPolicyRules = [
                {
                  Priority = network.prio;
                  Table = network.rt;
                }
              ];
            };
            dhcp-server = {
              matchConfig = {
                Type = "bridge";
                Name = "br-${networkName}";
              };
              networkConfig = base // {
                Address = [ network.ip4-cidr network.ip6-cidr ];
                ConfigureWithoutCarrier = true;
              };
              routingPolicyRules = [{
                Priority = 100;
                To = network.ip4-cidr;
              }];
            };
          }."${network.mode}" or {};
        }) networks);
    };
  };
}