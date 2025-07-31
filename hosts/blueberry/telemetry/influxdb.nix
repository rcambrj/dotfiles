{ config, ... }: {
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