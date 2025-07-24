{ config, ... }: {
  services.nginx.virtualHosts."loki.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
    };
  };

  services.loki = {
    enable = true;
    extraFlags = [
      # even if this is not needed, skip config validator because it segfaults
      "-config.expand-env=true"
    ];
    configuration = {
      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = 3100;
      };
      auth_enabled = false; # TODO: enable authentication
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore = {
            store = "inmemory";
          };
        };
        replication_factor = 1;
        path_prefix = config.services.loki.dataDir;
      };
      storage_config = {
        filesystem = {
          directory = "${config.services.loki.dataDir}/chunks";
        };
      };
      schema_config = {
        configs = [
          {
            from = "2020-05-15";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
      compactor = {
        working_directory = "${config.services.loki.dataDir}/retention";
        compaction_interval = "6h";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        delete_request_store = "filesystem";
      };
      limits_config = {
        retention_period = "14d";
      };
    };
  };
}