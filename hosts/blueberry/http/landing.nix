{ ... }: {
  services.nginx.virtualHosts."landing.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    root = ./landing;

    locations."/" = {
      index = "index.html";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."landing.home.cambridge.me" = {};
}