{ config, ... }: {
  # to allow moonraker to reboot, etc.
  security.polkit.enable = true;

  age-template.files.moonraker-secrets = {
    owner = config.services.moonraker.user;
    group = config.services.moonraker.group;
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
    stateDir = "/var/lib/printer_data";
    settings = {
      ldap = {
        ldap_host = "ldap.home.cambridge.me";
        ldap_port = 6360;
        ldap_secure = true;
        base_dn = "dc=cambridge,dc=me";
        bind_dn = "uid=admin-ro,ou=people,dc=cambridge,dc=me";
        bind_password = "{secrets.ldap.bind_password}";
        group_dn = "cn=fdm,ou=groups,dc=cambridge,dc=me";
      };
      authorization = {
        cors_domains = [ "https://fdm.cambridge.me" ];
        force_logins = false;
        trusted_clients = [
          "127.0.0.1" # allow mobileraker-companion to connect without a key
        ];
        default_source = "ldap";
      };
      octoprint_compat = {
        # used by slicers, eg. OrcaSlicer
      };
    };
  };

  # disable logging to disk, rely on journald
  systemd.services.moonraker.environment.MOONRAKER_LOG_PATH = "/dev/null";

  # restart moonraker when config changes (excludes secrets)
  systemd.services.moonraker.restartTriggers = [
    "${config.environment.etc."moonraker.cfg".source}"
  ];
}