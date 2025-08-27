{ config, lib, ... }:
with config.router;
with lib;
{
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

          tcp dport 22 accept comment "Keep this topmost so that SSH access doesnt get broken"

          iifname { "${home-netdev}", "${mgmt-netdev}" } accept
          iifname { "${wan-netdev}", "${lte-netdev}" } ct state { established, related } accept
          tcp flags syn / fin,syn,rst,ack jump syn_flood
          iifname { "${wan-netdev}", "${lte-netdev}" } icmp type { echo-request, destination-unreachable, time-exceeded } accept
          iifname "lo" accept
        }
        chain forward {
          type filter hook forward priority filter; policy drop;
          iifname { "${home-netdev}" } oifname { "${wan-netdev}", "${lte-netdev}" } accept
          iifname { "${wan-netdev}", "${lte-netdev}" } oifname { "${home-netdev}" } ct state { established, related } accept
        }
        chain syn_flood {
          limit rate 25/second burst 50 packets return
          drop
        }
        # chain dstnat {
        #   type nat hook prerouting priority dstnat; policy accept;
        #   meta nfproto ipv4 tcp dport 443 counter packets 11632 bytes 693642 dnat ip to 192.168.142.50:443 comment "!fw4: https"
        # }
      '';
    };
    tables.nat = {
      family = "ip";
      content = ''
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname { "${wan-netdev}", "${lte-netdev}" } masquerade
        }
      '';
    };
  };
}