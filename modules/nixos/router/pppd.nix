{ config, lib, pkgs, ... }:
with config.router;
with lib;
let
  perUplink = fn: concatMapAttrs (networkName: network: optionalAttrs (network.mode == "pppoe-uplink") (fn networkName network)) networks;
in {
  options = {};
  config = {
    services.pppd = {
      enable = true;
      peers = perUplink (networkName: network: {
        "${networkName}" = {
          enable = true;
          name = networkName;
          config = let
            # https://github.com/ppp-project/ppp/blob/master/pppd/ipcp.c "ppp_script_setenv"
            ipv4-up = pkgs.writeShellScript "pppd-${networkName}-ipv4-up" ''
              ${pkgs.iproute2}/bin/ip -4 route replace table ${toString network.rt} default via $IPREMOTE dev $IFNAME src $IPLOCAL
              ${pkgs.iproute2}/bin/ip -4 route replace table ${toString network.rt} $IPREMOTE dev $IFNAME scope link src $IPLOCAL
            '';
            ipv4-down = pkgs.writeShellScript "pppd-${networkName}-ipv4-down" ''
              ${pkgs.iproute2}/bin/ip -4 route flush table ${toString network.rt}
            '';

            # https://github.com/ppp-project/ppp/blob/master/pppd/ipv6cp.c "ppp_script_setenv"
            ipv6-up = pkgs.writeShellScript "pppd-${networkName}-ipv6-up" ''
              # LLREMOTE is a CIDR, but `ip route` expects an address
              LLREMOTE_ADDR="''${LLREMOTE%%/*}"
              ${pkgs.iproute2}/bin/ip -6 route replace table ${toString network.rt} default via $LLREMOTE_ADDR dev $IFNAME
              ${pkgs.iproute2}/bin/ip -6 route replace table ${toString network.rt} $LLREMOTE dev $IFNAME scope link src $LLLOCAL
            '';
            ipv6-down = pkgs.writeShellScript "pppd-${networkName}-ipv6-down" ''
              ${pkgs.iproute2}/bin/ip -6 route flush table ${toString network.rt}
            '';
          in concatStringsSep "\n" [
            # https://github.com/openwrt/openwrt/blob/main/package/network/services/ppp/files/ppp.sh
            # https://github.com/openwrt/openwrt/tree/main/package/network/services/ppp/files/lib/netifd
            # pppd help; pppd show-options

            "plugin pppoe.so"
            network.ifname-pppoe
            "ifname ${network.ifname}"
            "user internet password internet" # KPN doesn't care what the user/pass is

            "nodetach"
            "nolog"
            "lcp-echo-interval 1"
            "lcp-echo-failure 5"
            "lcp-echo-adaptive"
            "maxfail 1"
            "mtu 1500"
            "mru 1500"

            # pppd aquires link local addresses
            # public IPv6 acquired via DHCPv6-PD
            "noipv6" # TODO: enable ipv6
            # "+ipv6 ipv6cp-accept-local ipv6cp-use-persistent ipv6cp-accept-remote"

            # pppd doesn't support specifying a routing table, use up/down script
            "nodefaultroute"
            "nodefaultroute6"

            # use custom dns
            # "usepeerdns"

            "ip-up-script ${ipv4-up}"
            "ip-down-script ${ipv4-down}"

            "ipv6-up-script ${ipv6-up}"
            "ipv6-down-script ${ipv6-down}"
          ];
        };
      });
    };

    systemd.network.networks = perUplink (networkName: network: {
      "50-${network.ifname}" = {
        matchConfig = {
          Type = "ppp";
          Name = network.ifname;
        };
        networkConfig = {
          KeepConfiguration = "static";
          LLDP = "no";
          EmitLLDP = "no";
          IPv6AcceptRA = "no";
          IPv6SendRA = "no";
          # TODO: enable ipv6
          LinkLocalAddressing = "no";
          DHCP = "no";
          # LinkLocalAddressing = "ipv6";
          # DHCP = "ipv6";
          # DHCPPrefixDelegation = "yes";
        };
        dhcpV6Config = {
          SendHostname = "no";
          UseHostname = "no"; # Could not set hostname: Access denied
          WithoutRA = "solicit";
        };
        dhcpPrefixDelegationConfig = {
          UplinkInterface = ":self";
        };
      };
    });

    # if networkd restarts, pppoe connection breaks silently.
    systemd.services = perUplink (networkName: network: {
      "pppd-${networkName}" = {
        after = [ "systemd-networkd.service" ];
        partOf = [ "systemd-networkd.service" ];
      };
    });
  };
}