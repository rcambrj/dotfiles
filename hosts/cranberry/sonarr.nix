{ ... }: let
  group = import ./group.nix;
in {
  services.sonarr = {
    enable = true;
    group = group;
  };

  services.nginx.virtualHosts."sonarr.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:8989";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."sonarr.media.cambridge.me" = {};
}