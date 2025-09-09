{ pkgs, ... }: {
  systemd.services.primary-wan = {
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
        Type = "notify";
        Restart = "always";
        RestartSec = "60s";
    };
    script = ''
      while true; do
        # loop infinitely

        status=$(${pkgs.curl}/bin/curl --no-progress-meter -m 5 https://wan-status.router.cambridge.me || true)
        echo "$status"

        if [ "$(echo "$status" | ${pkgs.ripgrep}/bin/rg "interface wan is online" | wc -l)" != "1" ]; then
            echo "WAN is not up." >&2
            exit 1
        fi
        if [[ $(echo "$status" | grep "interface wan is" | wc -l) != "1" ]]; then
          echo Unable to determine WAN status, entering failsafe mode.
          WANONLINE=0
        else
          WANONLINE=$(echo "$status" | grep "interface wan is online" | wc -l)
        fi

        if [[ "$WANONLINE" != "1" ]]; then
          echo "WAN is not up." >&2
          exit 1
        fi

        echo "WAN is up." >&2
        systemd-notify --ready
        systemctl start downloads-enabled.target

        sleep 10
      done
    '';
  };
}