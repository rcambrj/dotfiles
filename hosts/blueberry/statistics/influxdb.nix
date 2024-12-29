{ config, ... }: {
  services.nginx.virtualHosts."influxdb.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://localhost:8086";
    };
  };

  services.influxdb2 = {
    enable = true;
    provision = {
      enable = true;
      initialSetup = {
        retention = 60 * 60 * 24 * 14;
        passwordFile = config.age.secrets.influxdb-admin-password.path;
        tokenFile = config.age.secrets.influxdb-admin-token.path;
        organization = "main";
        bucket = "default";
      };
      # once first start is complete, this takes no effect:
      # organizations = {};
    };
    settings = {};
  };
}