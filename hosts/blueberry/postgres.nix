{ config, lib, ... }: {
  services.postgresql = {
    enable = true;
    settings.listen_addresses = lib.mkForce "0.0.0.0";
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
}