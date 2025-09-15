# https://github.com/ghostbuster91/blogposts/blob/a2374f0039f8cdf4faddeaaa0347661ffc2ec7cf/router2023-part2/main.md
# https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/getting-started-with-nftables_configuring-and-managing-networking
# https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes
#

{ config, lib, pkgs, ... }:
with config.router;
with lib;
let
  uplinks = filterAttrs (networkName: network: elem network.mode [
    "dhcp-uplink" "pppoe-uplink" "static-uplink"
  ]) networks;
  uplinkIfnames = concatMapAttrsStringSep ", " (networkName: network: ''"${network.ifname}"'') uplinks;
  downlinks = filterAttrs (networkName: network: elem network.mode [
    "dhcp-server"
  ]) networks;
  downlinkIfnames = concatMapAttrsStringSep ", " (networkName: network: ''"${network.ifname}"'') downlinks;
in {
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

            tcp flags syn / fin,syn,rst,ack jump flood
            meta l4proto { icmp, icmpv6 } jump flood
            ${firewall.input}

            iifname { ${downlinkIfnames} } tcp dport 22 accept
            iifname { ${downlinkIfnames} } meta l4proto { icmp, icmpv6 } accept
            iifname { ${downlinkIfnames} } meta nfproto ipv4 udp dport 67 accept comment "DHCPv4 server"
            iifname { ${uplinkIfnames}   } meta nfproto ipv4 udp dport 68 accept comment "DHCPv4 client"
            iifname { ${downlinkIfnames} } meta nfproto ipv6 udp dport 547 accept comment "DHCPv6 server"
            iifname { ${uplinkIfnames}   } meta nfproto ipv6 udp dport 546 accept comment "DHCPv6 client"
            iifname { ${uplinkIfnames}   } ct state { established, related } accept
            iifname "lo" accept
          }
          chain forward {
            type filter hook forward priority filter; policy drop;

            tcp flags syn / fin,syn,rst,ack jump flood
            meta l4proto { icmp, icmpv6 } jump flood
            ${firewall.forward}

            iifname { ${downlinkIfnames} } oifname { ${uplinkIfnames} } accept
            iifname { ${uplinkIfnames} } oifname { ${downlinkIfnames} } ct state { established, related } accept

            # port forwards
            ${concatMapStringsSep "\n" (pf:
              ''iifname { ${uplinkIfnames} } ct status dnat ip daddr ${pf.to} ${pf.proto} dport { ${concatStringsSep "," pf.ports} } accept''
            ) port-forwards}
          }
          chain mangle_forward {
            type filter hook forward priority mangle; policy accept;
            iifname { ${uplinkIfnames} } tcp flags syn tcp option maxseg size set rt mtu
            oifname { ${uplinkIfnames} } tcp flags syn tcp option maxseg size set rt mtu
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

            # port forwards
            ${concatMapStringsSep "\n" (pf:
              ''iifname { ${uplinkIfnames} } ${pf.proto} dport { ${concatStringsSep "," pf.ports} } dnat to ${pf.to}''
            ) port-forwards}
          }
          chain srcnat {
            type nat hook postrouting priority srcnat;
            oifname { ${uplinkIfnames} } masquerade
          }
        '';
      };
    };
  };
}