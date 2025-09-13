# https://github.com/ghostbuster91/blogposts/blob/a2374f0039f8cdf4faddeaaa0347661ffc2ec7cf/router2023-part2/main.md
# https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/getting-started-with-nftables_configuring-and-managing-networking
# https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes
#

{ config, lib, pkgs, ... }:
with config.router;
with lib;
{
  options = {};
  config = {
    # networking.nat.externalInterface only supports one uplink
    networking.nat.enable = mkForce false;
    # so disable the nixos firewall
    networking.firewall.enable = mkForce false;
    # and let's roll some custom nftables
    networking.nftables = {
      enable = true;
      tables.filter = {
        family = "inet";
        content = ''
          chain input {
            type filter hook input priority filter; policy drop;

            ${firewall.input}

            tcp flags syn / fin,syn,rst,ack jump flood
            meta l4proto { icmp, icmpv6 } jump flood
            iifname { "${networks.lan.ifname}", "${networks.mgmt.ifname}" } accept
            iifname { "${networks.wan.ifname}", "${networks.lte.ifname}" } ct state { established, related } accept
            iifname { "${networks.wan.ifname}", "${networks.lte.ifname}" } meta nfproto ipv4 udp dport 68 accept comment DHCPv4
            iifname { "${networks.wan.ifname}", "${networks.lte.ifname}" } meta nfproto ipv6 udp dport 546 accept comment DHCPv6
            iifname "lo" accept
          }
          chain forward {
            type filter hook forward priority filter; policy drop;

            ${firewall.forward}

            tcp flags syn / fin,syn,rst,ack jump flood
            meta l4proto { icmp, icmpv6 } jump flood
            iifname { "${networks.lan.ifname}" } oifname { "${networks.wan.ifname}", "${networks.lte.ifname}" } accept
            iifname { "${networks.wan.ifname}", "${networks.lte.ifname}" } oifname { "${networks.lan.ifname}" } ct state { established, related } accept

            ${concatMapStringsSep "\n" (pf:
              ''iifname { "${networks.wan.ifname}", "${networks.lte.ifname}" } ct status dnat ip daddr ${pf.to} ${pf.proto} dport { ${concatStringsSep "," pf.ports} } accept''
            ) port-forwards}
          }
          chain mangle_forward {
            type filter hook forward priority mangle; policy accept;
            iifname { "${networks.wan.ifname}" } tcp flags syn tcp option maxseg size set rt mtu
            oifname { "${networks.wan.ifname}" } tcp flags syn tcp option maxseg size set rt mtu
          }
          chain flood {
            limit rate 25/second burst 50 packets return
            drop
          }
        '';
      };
      tables.nat = {
        family = "ip";
        content = ''
          chain dstnat {
            type nat hook prerouting priority dstnat;

            ${concatMapStringsSep "\n" (pf:
              ''iifname { "${networks.wan.ifname}", "${networks.lte.ifname}" } ${pf.proto} dport { ${concatStringsSep "," pf.ports} } dnat to ${pf.to}''
            ) port-forwards}
          }
          chain srcnat {
            type nat hook postrouting priority srcnat;
            oifname { "${networks.wan.ifname}", "${networks.lte.ifname}" } masquerade
          }
        '';
      };
    };
  };
}