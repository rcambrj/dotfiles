{ config, ... }: {
  services.postgresql = {
    enable = true;
  };

  # pgadmin regularly fails to come up. will investigate why when I can be bothered
  # services.pgadmin = {
  #   enable = true;
  #   initialEmail = "robert@cambridge.me";
  #   initialPasswordFile = config.age.secrets.blueberry-pgadmin.path;
  #   settings = {
  #     CONFIG_DATABASE_URI = "postgresql://%2Frun%2Fpostgresql";
  #   };
  # };

  services.postgresql.ensureUsers = [{
    name = "pgadmin";
    ensureClauses.superuser = true;
  }];

  services.nginx.virtualHosts."postgres.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://localhost:5050";
    };
  };

}