{ config, pkgs, ... }: {

  services.pia-vpn = {
    enable = true;
    certificateFile = ./ca.rsa.4096.crt;
    environmentFile = config.age.secrets.pia-vpn.path;
    region = "nl_amsterdam";
    networkConfig = ''
      [Match]
      Name = ''${interface}

      [Network]
      Description = WireGuard PIA network interface
      Address = ''${peerip}/32

      [RoutingPolicyRule]
      To = ''${wg_ip}/32
      Priority = 1000
      [RoutingPolicyRule]
      To = ''${meta_ip}/32
      Priority = 1000

      [RoutingPolicyRule]
      To = 0.0.0.0/0
      Priority = 2000
      Table = 42

      [Route]
      Destination = 0.0.0.0/0
      Table = 42
    '';
    portForward = {
      enable = true;
      script = ''
        export $(cat ${config.age-template.files.transmission-rpc-env-auth.path} | xargs)
        ${config.services.transmission.package}/bin/transmission-remote --authenv --port $port || true
      '';
    };
  };

  # restart the VPN once per day because it seems to just die occasionally
  # TODO: monitor connection and use sd_notify to kill service for restart
  systemd.timers.pia-vpn-restart = {
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      # OnCalendar = "minutely";
      Unit = "pia-vpn-restart.service";
    };
  };
  systemd.services.pia-vpn-restart = {
    description = "Restart the PIA VPN";
    requisite = [ "pia-vpn.service" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.systemd}/bin/systemctl restart pia-vpn.service
    '';
  };
}