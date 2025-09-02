{ config, lib, ... }:
with config.router;
with lib;
let
  noip = {
    # [Network]
    DHCP = "no";
    EmitLLDP = "no";
    IPv6AcceptRA = "no";
    IPv6SendRA = "no";
    LinkLocalAddressing = "no";
    LLDP = "no";
  };
in {
  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network = {
    config = {
      routeTables = {
        # these aliases are not used programmatically
        # just nice-to-haves for monitoring/debugging
        "wan" = networks.wan.rt;
        "lte" = networks.lte.rt;
      };
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
          Name = "${iface}-${networkName}";
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
        networkNamesUsingThisIface = attrNames (filterAttrs (networkName: network: elem iface network.ifaces.t) networks);
      in optionalAttrs (length networkNamesUsingThisIface > 0) {
        "10-${iface}" = {
          matchConfig = {
            Name = iface;
            Type = "ether";
          };
          networkConfig = noip // {
            VLAN = map (networkName: "${iface}-${networkName}") networkNamesUsingThisIface;
          };
        };
      }) ifaces)

      # attach networks to bridges
      // (concatMapAttrs (networkName: network: {}
        # tagged vlans
        // listToAttrs (map (iface: nameValuePair "20-${iface}-${networkName}" {
          matchConfig = {
            Type = "vlan";
            Name = "${iface}-${networkName}";
          };
          networkConfig.Bridge = "br-${networkName}";
        }) network.ifaces.t)

        # untagged ports
        // listToAttrs (map (iface: nameValuePair "30-${iface}" {
          matchConfig = {
            Type = "ether";
            Name = iface;
          };
          networkConfig.Bridge = "br-${networkName}";
        }) network.ifaces.u)
      ) networks)

      # configure bridges
      // (concatMapAttrs (networkName: network: {
        "40-${"br-${networkName}"}" = {
          dhcp-uplink = {
            matchConfig = {
              Type = "bridge";
              Name = "br-${networkName}";
            };
            networkConfig = {
              DHCP = "yes";
            };
            dhcpV4Config = {
              UseHostname = "no"; # Could not set hostname: Access denied
              RouteTable = network.rt;
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
            # TODO: what's needed here?
            routingPolicyRules = [
              {
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
            networkConfig = {
              Address = network.cidr;
            };
            routes = [{
              Gateway = network.gw;
              PreferredSource = network.ip;
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
            networkConfig = {
              Address = network.cidr;
              ConfigureWithoutCarrier = true;
            };
            routingPolicyRules = [{
              Priority = 100;
              To = network.cidr;
            }];
          };
        }."${network.mode}";
      }) networks);
  };
}