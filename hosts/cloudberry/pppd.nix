{ config, lib, pkgs, ... }:
with lib;
with config.router;
{
  services.pppd = {
    enable = true;
    peers.wan = {
      enable = !networks.wan.mode == "pppoe-uplink";
      name = "wan";
      # https://github.com/openwrt/openwrt/blob/main/package/network/services/ppp/files/ppp.sh
      # /usr/sbin/pppd
      #   nodetach
      #   ipparam wan
      #   ifname pppoe-wan
      #   lcp-echo-interval 1
      #   lcp-echo-failure 5
      #   lcp-echo-adaptive
      #   +ipv6
      #   set AUTOIPV6=1
      #   set PEERDNS=0
      #   nodefaultroute
      #   usepeerdns
      #   maxfail 1
      #   user internet
      #   password ????????
      #   ip-up-script /lib/netifd/ppp-up
      #   ipv6-up-script /lib/netifd/ppp6-up
      #   ip-down-script /lib/netifd/ppp-down
      #   ipv6-down-script /lib/netifd/ppp-down
      #   mtu 1492
      #   mru 1492
      #   plugin pppoe.so
      #   nic-eth0.6
      config = let
        # https://github.com/openwrt/openwrt/tree/main/package/network/services/ppp/files/lib/netifd
        ipv4-up = pkgs.writeShellScript "pppd-wan-ipv4-up" ''
          ${pkgs.iproute2}/bin/ip -4 route replace table ${networks.wan.rt} default via $IPREMOTE dev $IFNAME src $IPLOCAL
          ${pkgs.iproute2}/bin/ip -4 route replace table ${networks.wan.rt} $IPREMOTE dev $IFNAME scope link src $IPLOCAL
        '';
        ipv6-up = pkgs.writeShellScript "pppd-wan-ipv6-up" ''
          # TODO: ipv6
        '';
        ipv4-down = pkgs.writeShellScript "pppd-wan-ipv4-down" ''
          ${pkgs.iproute2}/bin/ip -4 route flush table ${networks.wan.rt}
        '';
        ipv6-down = pkgs.writeShellScript "pppd-wan-ipv6-down" ''
          # TODO: ipv6
        '';
      in (concatStringsSep "\n" [
        # "nodetach" # already set
        "lcp-echo-interval 1"
        "lcp-echo-failure 5"
        "ipv6"
        "hide-password"
        "nodefaultroute"
        # "usepeerdns"
        "maxfail 1"
        "mtu 1492"
        "mru 1492"
        "plugin pppoe.so"
        "ip-up-script ${ipv4-up}"
        "ipv6-up-script ${ipv6-up}"
        "ip-down-script ${ipv4-down}"
        "ipv6-down-script ${ipv6-down}"
        "nic-br-wan"
        "ifname pppoe-wan"
        # KPN doesn't care what the user/pass is
        "user internet"
        "password internet"
      ]);
    }
  };
}