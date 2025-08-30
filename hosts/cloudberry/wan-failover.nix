{ config, lib, pkgs, ... }:
with config.router;
with lib;
let
in {
  networking.nftables = {
    tables.lte-data-saver = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority filter + 10;

          oifname { "${lte-netdev}" } ip daddr ${lte-gw} accept comment "LTE dashboard"
          oifname { "${lte-netdev}" } meta l4proto { icmp, icmpv6 } accept
          oifname { "${lte-netdev}" } jump block-lte
        }
        chain output {
          type filter hook output priority filter + 10;

          oifname { "${lte-netdev}" } ip daddr ${lte-gw} accept comment "LTE dashboard"
          oifname { "${lte-netdev}" } meta l4proto { icmp, icmpv6 } accept
          oifname { "${lte-netdev}" } jump block-lte
        }

        chain block-lte {
          # LTE blocked by default. script to unblock in case of failover
          oifname "${lte-netdev}" reject
        }
      '';
    };
  };

  systemd.services.wan-failover = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      Type = "notify";
      NotifyAccess = "all";
    };
    environment = let
      set-lte-block = pkgs.writeShellScript "wan-failover-set-lte-block" ''
        set -eu
        TOGGLE="$1"
        # always start from a blank chain
        ${pkgs.nftables}/bin/nft flush chain inet lte-data-saver block-lte
        if [ "$TOGGLE" == "on" ]; then
          ${pkgs.nftables}/bin/nft add rule inet lte-data-saver block-lte oifname "${lte-netdev}" reject
        fi
      '';
    in {
      INTERVAL = "10s";          # sleep between checks; e.g. 10s, 1m
      RISE_N = "3";              # successes required to go UP
      FALL_N = "3";              # failures required to go DOWN
      INITIAL_STATE = "UNKNOWN"; # DOWN|UP|UNKNOWN
      CHECK_TIMEOUT = "5s";
      CHECK_CMD = toString (pkgs.writeShellScript "wan-failover-check" ''
        set -eu
        ${pkgs.iputils}/bin/ping -I ${wan-netdev} -c1 -W1 1.1.1.1 || ${pkgs.iputils}/bin/ping -I ${wan-netdev} -c1 -W1 8.8.8.8
      '');
      ON_UP_CMD = toString (pkgs.writeShellScript "wan-failover-up" ''
        ${pkgs.ifmetric}/bin/ifmetric ${wan-netdev} 1024
        ${pkgs.ifmetric}/bin/ifmetric ${lte-netdev} 2048
        ${set-lte-block} on
      '');
      ON_DOWN_CMD = toString (pkgs.writeShellScript "wan-failover-down" ''
        ${pkgs.ifmetric}/bin/ifmetric ${lte-netdev} 1024
        ${pkgs.ifmetric}/bin/ifmetric ${wan-netdev} 2048
        ${set-lte-block} off
      '');
    };
    script = toString (pkgs.writeShellScript "wan-failover" ''
      set -Eeuo pipefail

      state="$INITIAL_STATE"
      ok_count=0
      fail_count=0

      notify_status() {
        systemd-notify STATUS="state=$state ok=$ok_count fail=$fail_count"
      }

      transition_up() {
        state="UP"
        ok_count=0
        echo "Transitioned to UP"
        [[ -n "$ON_UP_CMD" ]] && $ON_UP_CMD || true
      }

      transition_down() {
        state="DOWN"
        fail_count=0
        echo "Transitioned to DOWN"
        [[ -n "$ON_DOWN_CMD" ]] && $ON_DOWN_CMD || true
      }

      trap 'echo "Exiting"; exit 0' INT TERM
      systemd-notify READY=1
      echo "Ready"

      while :; do
        if ${pkgs.coreutils}/bin/timeout "$CHECK_TIMEOUT" $CHECK_CMD; then
          # Success
          fail_count=0
          ok_count=$((ok_count + 1))
          if [[ "$state" != "UP" && "$ok_count" -ge "$RISE_N" ]]; then
            transition_up
          fi
          notify_status
        else
          # Failure
          ok_count=0
          fail_count=$((fail_count + 1))
          if [[ "$state" != "DOWN" && "$fail_count" -ge "$FALL_N" ]]; then
            transition_down
          fi
          notify_status
        fi

        sleep "$INTERVAL"
      done
    '');
  };
}
