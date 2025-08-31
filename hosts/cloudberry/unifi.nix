{ config, lib, pkgs, ... }:
with lib;
let
in {
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi;
    # MongoDB only supports migrating one major version at a time
    mongodbPackage = pkgs.mongodb-7_0;
  };

  services.nginx.virtualHosts."unifi.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "https://127.0.0.1:8443";
      extraConfig = ''
        proxy_ssl_verify off;
      '';
    };
  };
}