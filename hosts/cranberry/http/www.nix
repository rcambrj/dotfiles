{ ... }: {
  services.nginx.virtualHosts."media.cambridge.me" = {
    serverAliases = ["www.media.cambridge.me"];
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      return = "301 https://landing.home.cambridge.me";
    };
  };
}