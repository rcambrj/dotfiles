{ config, lib, ... }:
with config.router;
with lib;
{
  services.nginx.virtualHosts."lte.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      proxyPass = "http://${networks.lte.gw}/";
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_set_header Host $proxy_host;
      '';
    };
  };

  services.nginx.virtualHosts."switch-0.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      proxyPass = "http://${client-ips.switch-0}/";
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_set_header Host $proxy_host;
        proxy_set_header Content-Type $http_content_type;
      '';
    };
  };

  services.nginx.virtualHosts."switch-1.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      proxyPass = "http://${client-ips.switch-1}/";
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_set_header Host $proxy_host;
        proxy_set_header Content-Type $http_content_type;
      '';
    };
  };
}