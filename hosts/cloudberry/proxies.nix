{ config, lib, ... }:
with config.router;
with lib;
{
  services.nginx.virtualHosts."lte.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."= /" = {
      # fix javascript redirect
      return = "301 /index.html";
    };
    locations."/" = {
      proxyPass = "http://${networks.lte.ip4-gateway}/";
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
      # TL-SG108PE is really fussy about the http request
      extraConfig = ''
        gzip off;
        proxy_set_header Host $proxy_host;
        proxy_set_header Content-Type $http_content_type;
        proxy_set_header Cookie $http_cookie;
        proxy_set_header Referer $proxy_host;
      '';
    };
  };

  services.nginx.virtualHosts."switch-1.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      proxyPass = "http://${client-ips.switch-1}/";
      recommendedProxySettings = false;
      # TL-SG105PE is really fussy about the http request
      extraConfig = ''
        gzip off;
        proxy_set_header Host $proxy_host;
        proxy_set_header Content-Type $http_content_type;
        proxy_set_header Cookie $http_cookie;
        proxy_set_header Referer $proxy_host;
      '';
    };
  };
}