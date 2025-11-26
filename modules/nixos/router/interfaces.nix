
#
# processes config.router.networks into something meaningful for networkd.
#
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

  mkCakeConfig = network: direction: optionalAttrs (hasAttrByPath ["bw-${direction}"] network) {
    NAT = "yes";
    Bandwidth = network."bw-${direction}";
    AutoRateIngress = network."bw-${direction}-auto" or false;

    # https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html#PriorityQueueingPreset=
    # PriorityQueueingPreset = "besteffort";
    PriorityQueueingPreset = "diffserv3";
  };

  mkNetworkConfig = (network: (recursiveUpdate rec
    {
      networkConfig = base // noipv6;

      cakeConfig = mkCakeConfig network "egress";
    } {
      dhcp-uplink = {
        networkConfig = {
          DHCP = "ipv4";
        };
        dhcpV4Config = {
          UseHostname = "no"; # Could not set hostname: Access denied
          SendHostname = "no";
          RouteTable = network.rt;

          # odido-consument fixes:
          ClientIdentifier = "mac";
          RapidCommit = "no";
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
        routingPolicyRules = [
          {
            Family = "both";
            Priority = network.prio;
            Table = network.rt;
          }
        ];
      };
      static-uplink = {
        networkConfig = {
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
      dhcp-downlink = {
        networkConfig = {
          Address = [
            network.ip4-cidr
            # network.ip6-cidr # TODO: enable ipv6
          ];
          ConfigureWithoutCarrier = true;
          DHCPServer = "yes";
        };
        routingPolicyRules = [{
          Priority = 100;
          To = network.ip4-cidr;
        }];
        dhcpServerConfig = {
          PoolOffset = 128;
          PoolSize = 223;
          UplinkInterface = ":none";
          DNS = [ network.ip4-address ];
        };
        dhcpServerStaticLeases = flatten (map (host: {
          MACAddress = host.hwaddr;
          Address = host.ip;
        }) hosts);
      };
    }."${network.mode}" or {}));
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

      netdevs = (concatMapAttrs (networkName: network: {}
        # netdevs for tagged vlans
        // listToAttrs (map (iface: nameValuePair "10-${iface}-${networkName}" {
          netdevConfig = {
            Kind = "vlan";
            Name = "${iface}-${toString network.vlan}";
          };
          vlanConfig.Id = network.vlan;
        }) network.ifaces.t)
      ) networks)

      # netdevs for bridges
      // concatMapAttrs (networkName: network: {
        "20-br-${networkName}" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "br-${networkName}";
            MACAddress = network.mac;
          };
        };
      }) (filterAttrs (networkName: network: network.mode == "dhcp-downlink") networks)

      # netdevs for CAKE SQM QoS (ingress)
      // concatMapAttrs (networkName: network: {
        "30-sqm-${networkName}" = {
          netdevConfig = {
            Kind = "ifb";
            Name = "sqm-${networkName}";
          };
        };
      }) (filterAttrs (networkName: network: hasAttrByPath ["bw-ingress"] network) networks);

      networks = {}
        # configure physical ports
        // (concatMapAttrs (ifaceFriendly: iface: let
          # find all vlans for this iface
          taggedVLANs = attrValues (mapAttrs (networkName: network: network.vlan) (filterAttrs (networkName: network: elem iface network.ifaces.t) networks));
          untaggedBridges = attrNames (mapAttrs (networkName: network: network.vlan) (filterAttrs (networkName: network: network.mode == "dhcp-downlink" && elem iface network.ifaces.u) networks));
          # find network declaring this iface as main (ignore > 1)
          network = findFirst (network: iface == network.ifname || iface == (network.ifname-pppoe or "")) null (attrValues networks);
        in {
          "30-${iface}" = recursiveUpdate {
            matchConfig = {
              Name = iface;
              Type = "ether";
            };
            networkConfig = base // noipv6
              // (optionalAttrs (length taggedVLANs > 0) {
                VLAN = map (vlan: "${iface}-${toString vlan}") taggedVLANs;
              })
              // (optionalAttrs (length untaggedBridges > 0) {
                Bridge = "br-${elemAt untaggedBridges 0}";
              });
          } (optionalAttrs (network != null) (mkNetworkConfig network));
        }) ifaces)

        # configure tagged vlans
        // (concatMapAttrs (networkName: network: {}
          // listToAttrs (map (iface: let
              vlanIface = "${iface}-${toString network.vlan}";
              # is network declaring this iface as main?
              isMain = vlanIface == network.ifname || vlanIface == (network.ifname-pppoe or "");
            in (nameValuePair "40-${iface}-${networkName}" (recursiveUpdate {
              matchConfig = {
                Type = "vlan";
                Name = vlanIface;
              };
              networkConfig = optionalAttrs (network.mode == "dhcp-downlink") {
                Bridge = "br-${networkName}";
              };
            } (optionalAttrs isMain (mkNetworkConfig network))))
          ) (network.ifaces.t or []))
        ) networks)

        # configure bridges
        // (concatMapAttrs (networkName: network: {
          "50-br-${networkName}" = recursiveUpdate {
            matchConfig = {
              Name = "br-${networkName}";
              Type = "bridge";
            };
          } (mkNetworkConfig network);
        }) (filterAttrs (networkName: network: network.mode == "dhcp-downlink") networks));

        # configure CAKE SQM QoS (ingress)
        # TODO: this appears to fail sometimes, probably racing against the IFB creation script
        # // (concatMapAttrs (networkName: network: {
        #   "60-sqm-${networkName}" = {
        #     matchConfig = {
        #       Name = "sqm-${networkName}";
        #     };

        #     networkConfig.ConfigureWithoutCarrier = true;
        #     networkConfig.Activate = true;
        #     cakeConfig = mkCakeConfig network "ingress";
        #   };
        # }) (filterAttrs (networkName: network: hasAttrByPath ["bw-ingress"] network) networks));
    };
  };
}