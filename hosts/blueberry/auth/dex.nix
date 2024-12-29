{ config, flake, ... }: {
  services.nginx.virtualHosts."dex.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://localhost:5556";
    };
  };

  template.files.dex-env = {
    vars = {
      ldap_admin_password = config.age.secrets.ldap-admin-ro-password.path;
    };
    content = ''
      LDAP_ADMIN_PASSWORD=$ldap_admin_password
    '';
  };

  services.dex = {
    enable = true;
    environmentFile = config.template.files.dex-env.path;
    settings = {
      # logger = {
      #   level = "debug";
      #   format = "text";
      # };
      storage = {
        type = "memory";
      };
      issuer = "https://dex.home.cambridge.me";
      web = {
        http = "127.0.0.1:5556";
      };
      oauth2 = {
        grantTypes = [ "authorization_code" "refresh_token" ];
        responseTypes = [ "code" ];
        skipApprovalScreen = true;
        alwaysShowLoginScreen = false;
      };
      connectors = [{
        type = "ldap";
        id = "ldap";
        name = "LDAP";
        config = {
          host = "ldap.home.cambridge.me:6360";
          insecureNoSSL = false;
          insecureSkipVerify = false;
          rootCA = builtins.toString flake.lib.ldap-cert;
          bindDN = "uid=admin-ro,ou=people,dc=cambridge,dc=me";
          bindPW = "$LDAP_ADMIN_PASSWORD";
          userSearch = {
            baseDN = "ou=people,dc=cambridge,dc=me";
            username = "uid";
            idAttr = "uid";
            emailAttr = "mail";
            nameAttr = "displayName";
            preferredUsernameAttr = "uid";
          };
          groupSearch = {
            baseDN = "ou=groups,dc=cambridge,dc=me";
            filter = "(objectClass=groupOfUniqueNames)";
            userMatchers = [{
              userAttr = "DN";
              groupAttr = "member";
            }];
            nameAttr = "cn";
          };
        };
      }];
      staticClients = [
        {
          id = "blueberry-oauth2-proxy";
          redirectURIs = [ "https://oauth2-proxy.home.cambridge.me/oauth2/callback" ];
          name = "Blueberry";
          secretFile = config.age.secrets.blueberry-oauth2-proxy-client-secret.path;
        }
        {
          id = "cranberry-oauth2-proxy";
          redirectURIs = [ "https://oauth2-proxy.media.cambridge.me/oauth2/callback" ];
          name = "Cranberrry";
          secretFile = config.age.secrets.cranberry-oauth2-proxy-client-secret.path;
        }
      ];
    };
  };

  systemd.services.dex.restartTriggers = [
    config.template.files.dex-env.path
    config.age.secrets.blueberry-oauth2-proxy-client-secret.path
    config.age.secrets.cranberry-oauth2-proxy-client-secret.path
  ];
}