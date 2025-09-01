{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.up-or-down;
in {
  options.services.up-or-down = mkOption {
    description = "Periodically tests an arbitrary command for success/failure and resists histeria with rise/fall";
    type = types.attrsOf (types.submodule ({ ... }: {
      options = {
        interval = mkOption {
          description = "sleep between checks";
          default = "10s";
          example = "1m";
        };
        rise-n = mkOption {
          description = "successes required to go UP";
          default = 3;
        };
        fall-n = mkOption {
          description = "failures required to go DOWN";
          default = 3;
        };
        initial-state = mkOption {
          type = types.enum [ "DOWN" "UP" "UNKNOWN" ];
          default = "UNKNOWN";
        };
        check-timeout = mkOption {
          default = "5s";
        };
        check-cmd = mkOption {
          type = types.str;
        };
        on-up-cmd = mkOption {
          type = types.str;
        };
        on-down-cmd = mkOption {
          type = types.str;
        };
      };
    }));
  };
  config = {
    systemd.services = attrsets.concatMapAttrs (name: cfg': {
      "up-or-down-${name}" = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          Type = "notify";
          NotifyAccess = "all";
        };
        environment = {
          INTERVAL = cfg'.interval;
          RISE_N = toString cfg'.rise-n;
          FALL_N = toString cfg'.fall-n;
          INITIAL_STATE = cfg'.initial-state;
          CHECK_TIMEOUT = cfg'.check-timeout;
          CHECK_CMD = cfg'.check-cmd;
          ON_UP_CMD = cfg'.on-up-cmd;
          ON_DOWN_CMD = cfg'.on-down-cmd;
        };
        script = toString (pkgs.writeShellScript "up-or-down-${name}" ''
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
    }) cfg;
  };
}