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
    tables = {
      filter = {
        family = "inet";
        content = ''
          chain input {
            type filter hook input priority 0; policy drop;

            iifname { "${home-netdev}" } accept
            iifname { "${wan-netdev}", "${lte-netdev}" } ct state { established, related } accept
            tcp flags syn / fin,syn,rst,ack jump syn_flood
            iifname { "${wan-netdev}", "${lte-netdev}" } icmp type { echo-request, destination-unreachable, time-exceeded } counter accept
            iifname "lo" accept
          }
          chain output {
            type filter hook input priority 0; policy accept;
          }
          chain forward {
            type filter hook input priority 0; policy drop;
            iifname { "${home-netdev}" } oifname { "${wan-netdev}", "${lte-netdev}" } accept
          }
          chain syn_flood {
            limit rate 25/second burst 50 packets return
            drop
          }
        '';
      };
      nat = {
        family = "ip";
        content = ''
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname { "${wan-netdev}", "${lte-netdev}" } masquerade
          }
        '';
      };
    };
  };
}