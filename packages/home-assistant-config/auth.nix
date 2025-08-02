{ ... }: {
  "configuration.yaml".homeassistant.auth_providers = [
    {
      # https://github.com/lldap/lldap/blob/9ac96e8/example_configs/home-assistant.md
      type = "command_line";
      command = "/lldap-ha-auth.sh";
      args = [
        "https://ldap.home.cambridge.me"
        "homeassistant_user"
        "homeassistant_admin"
      ];
      meta = true;
    }
    # keep enabled.
    # use admin user for long-lived tokens, eg. google-assistant
    { type = "homeassistant"; }
  ];
}