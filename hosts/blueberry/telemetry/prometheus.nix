{ config, ... }: {
  services.nginx.virtualHosts."prometheus.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."prometheus.home.cambridge.me" = {};

  services.prometheus = {
    # fails to build.
    # TODO: reenable when stats are meaningful
    enable = false;

    scrapeConfigs = [
      {
        job_name = "node_exporter";
        scrape_interval = "15s";
        static_configs = [
          {
            targets = [
              "openwrt.cambridge.me:9100"
              "blueberry.cambridge.me:9100"
              "cranberry.cambridge.me:9100"
              "orange.cambridge.me:9100"
            ];
          }
        ];
      }
      {
        job_name = "energy";
        scrape_interval = "5m";
        static_configs = [
          {
            targets = [
              "dsmr.cambridge.me:80"
              "127.0.0.1:9126"
            ];
          }
        ];
      }
    ];
  };
}