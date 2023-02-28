{ ... }: let
  group = import ./group.nix;
in {
  services.nzbget = {
    enable = true;
    group = group;
  };

  services.nginx.virtualHosts."nzbget.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:6789";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."nzbget.media.cambridge.me" = {};
}