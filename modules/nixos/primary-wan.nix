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

        statuses=$(${pkgs.curl}/bin/curl --no-progress-meter -m 5 http://192.168.142.1:6926/interfaces || true)
        echo "$statuses"

        # Interface status:
        #  interface wan is online 18h:41m:16s, uptime 19h:36m:50s and tracking is active
        #  interface wan_lte is online 18h:41m:16s, uptime 120h:47m:35s and tracking is active

        if [ "$(echo "$statuses" | ${pkgs.ripgrep}/bin/rg "interface wan is online" | wc -l)" != "1" ]; then
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