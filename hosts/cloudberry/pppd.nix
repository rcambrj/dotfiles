{ config, lib, pkgs, ... }:
with lib;
with config.router;
{
  services.pppd = {
    enable = true;
    peers.wan = {
      enable = networks.wan.mode == "pppoe-uplink";
      name = "wan";
      config = let
        ipv4-up = pkgs.writeShellScript "pppd-wan-ipv4-up" ''
          ${pkgs.iproute2}/bin/ip -4 route replace table ${toString networks.wan.rt} default via $IPREMOTE dev $IFNAME src $IPLOCAL
          ${pkgs.iproute2}/bin/ip -4 route replace table ${toString networks.wan.rt} $IPREMOTE dev $IFNAME scope link src $IPLOCAL
        '';
        ipv6-up = pkgs.writeShellScript "pppd-wan-ipv6-up" ''
          # TODO: ipv6
        '';
        ipv4-down = pkgs.writeShellScript "pppd-wan-ipv4-down" ''
          ${pkgs.iproute2}/bin/ip -4 route flush table ${toString networks.wan.rt}
        '';
        ipv6-down = pkgs.writeShellScript "pppd-wan-ipv6-down" ''
          # TODO: ipv6
        '';
      in concatStringsSep "\n" [
          # https://github.com/openwrt/openwrt/blob/main/package/network/services/ppp/files/ppp.sh
          # https://github.com/openwrt/openwrt/tree/main/package/network/services/ppp/files/lib/netifd
          # pppd help; pppd show-options

          "plugin pppoe.so"
          "br-wan"
          "ifname pppoe-wan"
          "user internet password internet" # KPN doesn't care what the user/pass is

          "nodetach"
          "nolog"
          "lcp-echo-interval 1"
          "lcp-echo-failure 5"
          "lcp-echo-adaptive"
          "noipv6" # deal with this challenge another day
          "maxfail 1"
          "mtu 1492"
          "mru 1492"
          "nodefaultroute"
          # "usepeerdns"

          "ip-up-script ${ipv4-up}"
          "ipv6-up-script ${ipv6-up}"
          "ip-down-script ${ipv4-down}"
          "ipv6-down-script ${ipv6-down}"
        ];
    };
  };
}