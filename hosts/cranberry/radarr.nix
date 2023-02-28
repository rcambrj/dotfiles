{ ... }: let
  group = import ./group.nix;
in {
  services.radarr = {
    enable = true;
    group = group;
  };

  services.nginx.virtualHosts."radarr.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:7878";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."radarr.media.cambridge.me" = {};
}