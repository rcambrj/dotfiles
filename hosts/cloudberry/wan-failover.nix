{ config, flake, lib, pkgs, ... }:
with config.router;
with lib;
let
  wan-status-dir = "/var/run/wan-status";
  wan-status-file = "${wan-status-dir}/index.txt";
in {
  imports = [
    flake.nixosModules.up-or-down
  ];

  networking.nftables = {
    tables.lte-data-saver = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority filter + 10;

          oifname { "${lte-netdev}" } ip daddr ${lte-gw} accept comment "LTE dashboard"
          oifname { "${lte-netdev}" } meta l4proto { icmp, icmpv6 } accept
          oifname "${lte-netdev}" jump block-lte
        }
        chain output {
          type filter hook output priority filter + 10;

          oifname "${lte-netdev}" ip daddr ${lte-gw} accept comment "LTE dashboard"
          oifname "${lte-netdev}" meta l4proto { icmp, icmpv6 } accept
          oifname "${lte-netdev}" jump block-lte
        }
        chain block-lte {
          # LTE blocked by default. script to unblock in case of failover
          oifname "${lte-netdev}" reject
        }
        chain postrouting {
          type filter hook postrouting priority mangle; policy accept;
          oifname "${lte-netdev}" ct mark set ${lte-ct}
        }
      '';
    };
  };

  services.up-or-down.wan-failover = let
    lte-block-off = pkgs.writeTextFile {
      name = "wan-failover-lte-block-off";
      text = ''
        flush chain inet lte-data-saver block-lte
      '';
    };
    lte-block-on = pkgs.writeTextFile {
      name = "wan-failover-lte-block-on";
      text = ''
        flush chain inet lte-data-saver block-lte
        add rule inet lte-data-saver block-lte oifname "${lte-netdev}" reject
      '';
    };
  in {
    interval = "10s";
    rise-n = "3";
    fall-n = "3";
    initial-state = "UNKNOWN";
    check-timeout = "5s";
    check-cmd = toString (pkgs.writeShellScript "wan-failover-check" ''
      set -eu
      ${pkgs.iputils}/bin/ping -I ${wan-netdev} -c1 -W1 1.1.1.1 || ${pkgs.iputils}/bin/ping -I ${wan-netdev} -c1 -W1 8.8.8.8
    '');

    on-up-cmd = toString (pkgs.writeShellScript "wan-failover-up" ''
      echo "Switching route rule priorities..."
      ${pkgs.iproute2}/bin/ip -4 rule delete priority ${toString uplink-rule-override} table ${toString lte-rt} || true
      echo "Blocking LTE traffic..."
      ${pkgs.nftables}/bin/nft -f ${lte-block-on} || true
      echo "Flushing conntrack..."
      ${pkgs.conntrack-tools}/bin/conntrack -D -f ipv4 --mark ${lte-ct}/${lte-ct} || true
      echo "Updating status file..."
      echo "interface wan is online" > ${wan-status-file}
    '');
    on-down-cmd = toString (pkgs.writeShellScript "wan-failover-down" ''
      echo "Switching route rule priorities..."
      ${pkgs.iproute2}/bin/ip -4 rule add priority ${toString uplink-rule-override} table ${toString lte-rt} || true
      echo "Permitting LTE traffic..."
      ${pkgs.nftables}/bin/nft -f ${lte-block-off} || true
      echo "Updating status file..."
      echo "interface wan is offline" > ${wan-status-file}
    '');
  };

  systemd.tmpfiles.settings = {
    "10-wan-status-dir"."${wan-status-dir}".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };

  services.nginx.virtualHosts."wan-status.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      root = wan-status-dir;
      index = "index.txt";
    };
  };
}
