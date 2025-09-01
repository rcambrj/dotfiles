# https://github.com/ghostbuster91/blogposts/blob/a2374f0039f8cdf4faddeaaa0347661ffc2ec7cf/router2023-part2/main.md
# https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/getting-started-with-nftables_configuring-and-managing-networking
# https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes
#

{ config, lib, ... }:
with config.router;
with lib;
let
  port-forwards = [
    { proto = "tcp"; ports = [ "443" ]; to = client-ips.kubernetes-lb; }

    # wreckfest
    { proto = "tcp"; ports = [ "27015-27016" "33540" ]; to = client-ips.gaming-pc; }
    { proto = "udp"; ports = [ "27015-27016" "33540" ]; to = client-ips.gaming-pc; }
  ];
  netbird-netdev = config.services.netbird.clients.default.interface;
in {
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

          tcp dport 22 accept

          ip saddr ${client-ips.solar0} drop
          iifname != "lo" tcp dport 8443 drop comment "Unifi controller self-signed HTTPS"

          iifname { "${home-netdev}", "${mgmt-netdev}", "${netbird-netdev}" } accept
          iifname { "${wan-netdev}", "${lte-netdev}" } ct state { established, related } accept
          tcp flags syn / fin,syn,rst,ack jump syn_flood
          iifname { "${wan-netdev}", "${lte-netdev}" } meta l4proto { icmp, icmpv6 } limit rate 100/second accept
          iifname { "${wan-netdev}", "${lte-netdev}" } meta nfproto ipv4 udp dport 68 accept comment DHCPv4
          iifname { "${wan-netdev}", "${lte-netdev}" } meta nfproto ipv6 udp dport 546 accept comment DHCPv6
          iifname { "${wan-netdev}", "${lte-netdev}" } udp dport ${toString config.services.netbird.clients.default.port} accept
          iifname "lo" accept
        }
        chain forward {
          type filter hook forward priority filter; policy drop;
          iifname { "${home-netdev}" } oifname { "${netbird-netdev}", "${wan-netdev}", "${lte-netdev}" } accept
          iifname { "${netbird-netdev}"} oifname { "${home-netdev}" }
          iifname { "${wan-netdev}", "${lte-netdev}" } oifname { "${home-netdev}" } ct state { established, related } accept

          ${concatMapStringsSep "\n" (pf:
            ''iifname { "${wan-netdev}", "${lte-netdev}" } ct status dnat ip daddr ${pf.to} ${pf.proto} dport { ${concatStringsSep "," pf.ports} } accept''
          ) port-forwards}
        }
        chain syn_flood {
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
            ''iifname { "${wan-netdev}", "${lte-netdev}" } ${pf.proto} dport { ${concatStringsSep "," pf.ports} } dnat to ${pf.to}''
          ) port-forwards}
        }
        chain srcnat {
          type nat hook postrouting priority srcnat;
          oifname { "${wan-netdev}", "${lte-netdev}" } masquerade
        }
      '';
    };
  };
}