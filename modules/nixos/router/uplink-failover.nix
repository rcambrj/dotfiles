{ config, inputs, lib, pkgs, ... }:
with config.router;
with lib;
let
  wan-status-dir = "/var/run/wan-status";
  wan-status-file = "${wan-status-dir}/index.txt";
in {
  imports = [
    ../up-or-down.nix
  ];
  options = {};
  config = mkIf (
    (uplink-failover.primary   or "") != "" &&
    (uplink-failover.secondary or "") != ""
  ) (let
    primary   = networks."${uplink-failover.primary}";
    secondary = networks."${uplink-failover.secondary}";
  in {

    networking.nftables = {
      tables.secondary-uplink-data-saver = {
        family = "inet";
        content = ''
          chain forward {
            type filter hook forward priority filter + 10;

            ${firewall.uplink-failover.forward}

            oifname { "${secondary.ifname}" } meta l4proto { icmp, icmpv6 } accept
            oifname "${secondary.ifname}" jump block-secondary-uplink
          }
          chain output {
            type filter hook output priority filter + 10;

            ${firewall.uplink-failover.output}

            oifname "${secondary.ifname}" meta l4proto { icmp, icmpv6 } accept
            oifname "${secondary.ifname}" jump block-secondary-uplink
          }
          chain block-secondary-uplink {
            # secondary blocked by default. script to unblock in case of failover
            oifname "${secondary.ifname}" reject
          }
          chain postrouting {
            type filter hook postrouting priority mangle; policy accept;
            oifname "${secondary.ifname}" ct mark set ${secondary.ct}
          }
        '';
      };
    };

    services.up-or-down.uplink-failover = let
      secondary-uplink-block-off = pkgs.writeTextFile {
        name = "uplink-failover-secondary-uplink-block-off";
        text = ''
          flush chain inet secondary-uplink-data-saver block-secondary-uplink
        '';
      };
      secondary-uplink-block-on = pkgs.writeTextFile {
        name = "uplink-failover-secondary-uplink-block-on";
        text = ''
          flush chain inet secondary-uplink-data-saver block-secondary-uplink
          add rule inet secondary-uplink-data-saver block-secondary-uplink oifname "${secondary.ifname}" reject
        '';
      };
      notify-telegram = pkgs.writeShellScript "uplink-failover-notify-telegram" ''
        TOKEN="$(cat ${config.router.telegram-token-path})"
        CHAT_ID="$(cat ${config.router.telegram-group-path})"
        TEXT="$1"

        sleep 5s
        ${pkgs.curl}/bin/curl "https://api.telegram.org/bot$TOKEN/sendMessage" --data-urlencode "chat_id=$CHAT_ID" --data-urlencode "text=$TEXT" --no-progress-meter &
      '';
    in {
      interval = "10s";
      rise-n = "3";
      fall-n = "3";
      initial-state = "UNKNOWN";
      check-timeout = "5s";

      check-cmd = toString (pkgs.writeShellScript "uplink-failover-check" ''
        set -eu
        ${concatMapStringsSep " || " (target:
          ''${pkgs.iputils}/bin/ping -I ${primary.ifname} -c1 -W1 ${target} > /dev/null''
        ) primary.ping-targets}
      '');

      on-up-cmd = toString (pkgs.writeShellScript "uplink-failover-up" ''
        echo "Switching route rule priorities..."
        ${pkgs.iproute2}/bin/ip -4 rule delete priority ${toString uplink-failover.rule-prio.override} table ${toString secondary.rt} || true

        echo "Blocking secondary uplink traffic..."
        ${pkgs.nftables}/bin/nft -f ${secondary-uplink-block-on} || true

        echo "Flushing conntrack..."
        ${pkgs.conntrack-tools}/bin/conntrack -D -f ipv4 --mark ${secondary.ct}/${secondary.ct} || true

        echo "Updating status file..."
        echo "interface wan is online" > ${wan-status-file} || true

        echo "Notifying telegram..."
        ${notify-telegram} "wan online" || true
      '');

      on-down-cmd = toString (pkgs.writeShellScript "uplink-failover-down" ''
        echo "Switching route rule priorities..."
        ${pkgs.iproute2}/bin/ip -4 rule add priority ${toString uplink-failover.rule-prio.override} table ${toString secondary.rt} || true

        echo "Permitting secondary uplink traffic..."
        ${pkgs.nftables}/bin/nft -f ${secondary-uplink-block-off} || true

        echo "Updating status file..."
        echo "interface wan is offline" > ${wan-status-file} || true

        echo "Notifying telegram..."
        ${notify-telegram} "wan offline" || true
      '');
    };

    systemd.tmpfiles.settings = {
      "10-wan-status-dir"."${wan-status-dir}".d = {
        user = "root";
        group = "root";
        mode = "0755";
      };
    };
  });
}