{ ... }: {
  services.nginx.virtualHosts."jackett.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:9117";
    };
  };

  services.jackett = {
    enable = true;
    group = "media";
  };

  systemd.services.jackett = {
    after = [ "pia-vpn.service" ];
    bindsTo = [ "pia-vpn.service" ];
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  services.oauth2-proxy.nginx.virtualHosts."jackett.media.cambridge.me" = {};
}