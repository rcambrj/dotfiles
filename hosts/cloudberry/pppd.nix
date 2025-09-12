{ config, lib, pkgs, ... }:
with lib;
with config.router;
let
  network = networks.wan;
in {
  services.pppd = {
    enable = true;
    peers.wan = {
      enable = network.mode == "pppoe-uplink";
      name = "wan";
      config = let
        # https://github.com/ppp-project/ppp/blob/master/pppd/ipcp.c "ppp_script_setenv"
        ipv4-up = pkgs.writeShellScript "pppd-wan-ipv4-up" ''
          ${pkgs.iproute2}/bin/ip -4 route replace table ${toString network.rt} default via $IPREMOTE dev $IFNAME src $IPLOCAL
          ${pkgs.iproute2}/bin/ip -4 route replace table ${toString network.rt} $IPREMOTE dev $IFNAME scope link src $IPLOCAL
        '';
        ipv4-down = pkgs.writeShellScript "pppd-wan-ipv4-down" ''
          ${pkgs.iproute2}/bin/ip -4 route flush table ${toString network.rt}
        '';

        # https://github.com/ppp-project/ppp/blob/master/pppd/ipv6cp.c "ppp_script_setenv"
        ipv6-up = pkgs.writeShellScript "pppd-wan-ipv6-up" ''
          # LLREMOTE is a CIDR, but `ip route` expects an address
          LLREMOTE_ADDR="''${LLREMOTE%%/*}"
          ${pkgs.iproute2}/bin/ip -6 route replace table ${toString network.rt} default via $LLREMOTE_ADDR dev $IFNAME
          ${pkgs.iproute2}/bin/ip -6 route replace table ${toString network.rt} $LLREMOTE dev $IFNAME scope link src $LLLOCAL
        '';
        ipv6-down = pkgs.writeShellScript "pppd-wan-ipv6-down" ''
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
          "mtu 1492"
          "mru 1492"

          # KPN provides IPv6 via DHCPv6, pppd aquires link local addresses
          # "noipv6"
          "+ipv6 ipv6cp-accept-local ipv6cp-use-persistent ipv6cp-accept-remote"

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
  };

  systemd.network.networks = optionalAttrs (network.mode == "pppoe-uplink") {
    "50-${network.ifname}" = {
      matchConfig = {
        Type = "ppp";
        Name = network.ifname;
      };
      networkConfig = {
        KeepConfiguration = "static";
        LLDP = "no";
        EmitLLDP = "no";
        LinkLocalAddressing = "ipv6";
        IPv6AcceptRA = "no";
        IPv6SendRA = "no";
        DHCP = "ipv6";
        DHCPPrefixDelegation = "yes";
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
  };

  # if networkd restarts, pppoe connection breaks silently.
  systemd.services.pppd-wan = {
    after = [ "systemd-networkd.service" ];
    partOf = [ "systemd-networkd.service" ];
  };
}