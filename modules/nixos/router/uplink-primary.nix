{ config, inputs, lib, pkgs, ... }:
with config.router;
with lib;
let
  wan-status-dir = "/run/wan-status";
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
    tailscaleFwmark = "0x80000/0xff0000";
    tailscaleRulePrio = uplink-failover.rule-prio.tailscale or 5240;
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
      reconcile-state = pkgs.writeShellScript "uplink-failover-reconcile-state" ''
        set -eu

        ip=${pkgs.iproute2}/bin/ip
        jq=${pkgs.jq}/bin/jq
        nft=${pkgs.nftables}/bin/nft

        ensure_rule() {
          priority="$1"
          read -r -a rule <<< "$2"

          if $ip -j -4 rule show priority "$priority" "''${rule[@]}" | $jq -e 'length == 1' > /dev/null; then
            return
          fi

          echo "Reconciling policy rule $priority..."
          $ip -4 rule delete priority "$priority" || true
          $ip -4 rule add priority "$priority" "''${rule[@]}"
        }

        remove_rule() {
          priority="$1"
          if $ip -j -4 rule show priority "$priority" | $jq -e 'length != 0' > /dev/null; then
            echo "Removing policy rule $priority..."
            $ip -4 rule delete priority "$priority" || true
          fi
        }

        state="$1"
        case "$state" in
          up)
            tailscale_table="${uplink-failover.primary}"
            override_table=""
            should_block_secondary_uplink=true
            wan_status="interface wan is online"
            ;;
          down)
            tailscale_table="${uplink-failover.secondary}"
            override_table="${uplink-failover.secondary}"
            should_block_secondary_uplink=false
            wan_status="interface wan is offline"
            ;;
          *)
            exit 1
            ;;
        esac

        # Tailscale marks its own control traffic to keep it off the tunnel.
        # It needs an explicit route because the uplink defaults live outside main.
        ensure_rule ${toString tailscaleRulePrio} "fwmark ${tailscaleFwmark} table $tailscale_table"

        if [[ -z "$override_table" ]]; then
          remove_rule ${toString uplink-failover.rule-prio.override}
        else
          ensure_rule ${toString uplink-failover.rule-prio.override} "table $override_table"
        fi

        chain="$($nft list chain inet secondary-uplink-data-saver block-secondary-uplink)"
        if [[ "$should_block_secondary_uplink" == true ]]; then
          if [[ "$chain" != *"oifname \"${secondary.ifname}\" reject"* ]]; then
            echo "Blocking secondary uplink..."
            $nft -f ${secondary-uplink-block-on}
          fi
        elif [[ "$chain" == *oifname* ]]; then
          echo "Unblocking secondary uplink..."
            $nft -f ${secondary-uplink-block-off}
        fi

        current_status=""
        [[ -f ${wan-status-file} ]] && IFS= read -r current_status < ${wan-status-file}
        if [[ "$current_status" != "$wan_status" ]]; then
          echo "Updating WAN status..."
          printf '%s\n' "$wan_status" > ${wan-status-file}
        fi
      '';
      notify-telegram = pkgs.writeShellScript "uplink-failover-notify-telegram" ''
        TOKEN="$(cat ${config.router.telegram-token-path})"
        CHAT_ID="$(cat ${config.router.telegram-group-path})"
        TEXT="$1"

        sleep 5s
        ${pkgs.curl}/bin/curl "https://api.telegram.org/bot$TOKEN/sendMessage" --data-urlencode "chat_id=$CHAT_ID" --data-urlencode "text=$TEXT" --no-progress-meter &
      '';
    in {
      interval = uplink-failover.interval;
      run-hooks-while-stable = true;
      rise-n = uplink-failover.rise-n;
      fall-n = uplink-failover.fall-n;
      initial-state = "UNKNOWN";
      check-timeout = "5s";

      check-cmd = toString (pkgs.writeShellScript "uplink-failover-check" ''
        set -eu
        ${concatMapStringsSep " || " (target:
          ''${pkgs.iputils}/bin/ping -I ${primary.ifname} -c1 -W1 ${target} > /dev/null''
        ) primary.ping-targets}
      '');

      on-up-cmd = toString (pkgs.writeShellScript "uplink-failover-up" ''
        ${reconcile-state} up
        if [[ "$1" == true ]]; then
          echo "Flushing conntrack..."
          ${pkgs.conntrack-tools}/bin/conntrack -D -f ipv4 --mark ${secondary.ct}/${secondary.ct} || true

          echo "Notifying telegram..."
          ${notify-telegram} "🛜✅ wan online" || true
        fi
      '');

      on-down-cmd = toString (pkgs.writeShellScript "uplink-failover-down" ''
        ${reconcile-state} down
        if [[ "$1" == true ]]; then
          echo "Notifying telegram..."
          ${notify-telegram} "🛜⚠️ wan offline" || true
        fi
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
