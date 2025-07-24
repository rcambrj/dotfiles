{ ... }: {
  services.nginx.virtualHosts."esphome.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:6052";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."esphome.home.cambridge.me" = {};

  services.esphome = {
    enable = true;
    usePing = true;
    address = "0.0.0.0";
  };
}