{ config, ... }: {
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