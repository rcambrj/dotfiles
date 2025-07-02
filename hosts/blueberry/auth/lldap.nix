{ config, flake, ... }: {
  networking.firewall.allowedTCPPorts = [
    # 3890 # LDAP (insecure)
    6360 # LDAPS
  ];

  services.postgresql.ensureDatabases = [ "lldap" ];
  services.postgresql.ensureUsers = [{
    name = "lldap";
    ensureDBOwnership = true;
  }];

  services.nginx.virtualHosts."ldap.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:5324";
    };
  };

  users.users.lldap = {
    uid = 5324;
    group = "lldap";
    isSystemUser = true;
  };
  users.groups.lldap = {
    gid = 5324;
  };

  services.lldap = {
    enable = true;
    environment = {
      LLDAP_JWT_SECRET_FILE = config.age.secrets.lldap-jwt-secret.path;
      LLDAP_LDAPS_OPTIONS__ENABLED = "true";
      LLDAP_LDAPS_OPTIONS__CERT_FILE = "${flake.lib.ldap-cert}";
      LLDAP_LDAPS_OPTIONS__KEY_FILE = config.age.secrets.lldap-cert-key.path;
      LLDAP_SMTP_OPTIONS__ENABLE_PASSWORD_RESET = "true";
      LLDAP_SMTP_OPTIONS__FROM = "ldap@cambridge.me";
      LLDAP_SMTP_OPTIONS__TO = "noreply@cambridge.me"; # reply to
      LLDAP_SMTP_OPTIONS__SERVER = "smtp.eu.mailgun.org";
      LLDAP_SMTP_OPTIONS__PORT = "465";
      LLDAP_SMTP_OPTIONS__USER = "postmaster@mailgun.cambridge.me";
      # LLDAP_SMTP_OPTIONS__PASSWORD = see environmentFile
      LLDAP_SMTP_OPTIONS__SMTP_ENCRYPTION = "TLS";
    };
    environmentFile = config.age.secrets.lldap-env.path;
    settings = {
      # verbose = true;
      http_host = "127.0.0.1";
      http_port = 5324;
      http_url = "https://ldap.home.cambridge.me";
      ldap_host = "0.0.0.0";
      ldap_base_dn = "dc=cambridge,dc=me";
      ldap_user_email = "admin@cambridge.me";
      database_url = "postgresql://lldap?host=/run/postgresql";
    };
  };
}