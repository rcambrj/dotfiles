{ ... }: {
  services.nginx.virtualHosts."esphome.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://localhost:6052";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."esphome.home.cambridge.me" = {};

  services.esphome = {
    enable = true;
    usePing = true;
  };
}