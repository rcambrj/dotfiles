#
# doesn't change any firewall rules or routes, just notifies
#
{ config, inputs, lib, pkgs, ... }:
with config.router;
with lib;
{
  imports = [
    ../up-or-down.nix
  ];
  options = {};
  config = mkIf (
    (uplink-failover.secondary or "") != ""
  ) (let
    secondary = networks."${uplink-failover.secondary}";
  in {
    services.up-or-down.uplink-secondary = let
      notify-telegram = pkgs.writeShellScript "uplink-secondary-notify-telegram" ''
        TOKEN="$(cat ${config.router.telegram-token-path})"
        CHAT_ID="$(cat ${config.router.telegram-group-path})"
        TEXT="$1"

        sleep 5s
        ${pkgs.curl}/bin/curl "https://api.telegram.org/bot$TOKEN/sendMessage" --data-urlencode "chat_id=$CHAT_ID" --data-urlencode "text=$TEXT" --no-progress-meter &
      '';
    in {
      interval = uplink-failover.interval;
      rise-n = uplink-failover.rise-n;
      fall-n = uplink-failover.fall-n;
      initial-state = "UNKNOWN";
      check-timeout = "5s";

      check-cmd = toString (pkgs.writeShellScript "uplink-failover-check" ''
        set -eu
        ${concatMapStringsSep " || " (target:
          ''${pkgs.iputils}/bin/ping -I ${secondary.ifname} -c1 -W1 ${target} > /dev/null''
        ) secondary.ping-targets}
      '');

      on-up-cmd = toString (pkgs.writeShellScript "uplink-failover-up" ''
        echo "Notifying telegram..."
        ${notify-telegram} "📶✅ lte online" || true
      '');

      on-down-cmd = toString (pkgs.writeShellScript "uplink-failover-down" ''
        echo "Notifying telegram..."
        ${notify-telegram} "📶⚠️ lte offline" || true
      '');
    };
  });
}