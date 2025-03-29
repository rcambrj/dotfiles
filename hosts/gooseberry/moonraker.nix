{ config, ... }: {
  # to allow moonraker to reboot, etc.
  security.polkit.enable = true;

  template.files.moonraker-secrets = {
    owner = config.services.moonraker.user;
    # docs say secrets.ini or secrets.json, but they're wrong
    path = "${config.services.moonraker.stateDir}/moonraker.secrets";
    vars = {
      ldap_admin_password = config.age.secrets.ldap-admin-ro-password.path;
    };
    content = ''
      [ldap]
      bind_password: $ldap_admin_password
    '';
  };

  services.moonraker = {
    enable = true;
    allowSystemControl = true;
    group = config.services.klipper.group;
    settings = {
      ldap = {
        ldap_host = "ldap.home.cambridge.me";
        ldap_port = 6360;
        ldap_secure = true;
        base_dn = "dc=cambridge,dc=me";
        bind_dn = "uid=admin-ro,ou=people,dc=cambridge,dc=me";
        bind_password = "{secrets.ldap.bind_password}";
        # group_dn = "cn=fdm,ou=groups,dc=cambridge,dc=me";
      };
      authorization = {
        cors_domains = [ "https://fdm.cambridge.me" ];
        force_logins = true;
        default_source = "ldap";
      };
    };
  };

}