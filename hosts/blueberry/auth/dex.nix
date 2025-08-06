{ config, flake, ... }: {
  age-template.files.dex-env = {
    vars = {
      ldap_admin_password = config.age.secrets.ldap-admin-ro-password.path;
    };
    content = ''
      LDAP_ADMIN_PASSWORD=$ldap_admin_password
    '';
  };

  services.dex = {
    enable = true;
    environmentFile = config.age-template.files.dex-env.path;
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
        http = "0.0.0.0:5556";
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
          host = "lldap.home.cambridge.me:6360";
          insecureNoSSL = false;
          # temporarily disable tls check during transition to kubernetes
          insecureSkipVerify = true;
          # rootCA = "${flake.lib.ldap-cert}";
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
          id = "kubernetes-oauth2-proxy";
          redirectURIs = [ "https://oauth2-proxy.home.cambridge.me/oauth2/callback" ];
          name = "Kubernetes";
          secretFile = config.age.secrets.kubernetes-oauth2-proxy-client-secret.path;
        }
        {
          id = "argocd";
          redirectURIs = [ "https://argocd.home.cambridge.me/auth/callback" ];
          name = "Argo CD";
          secretFile = config.age.secrets.argocd-client-secret.path;
        }
      ];
    };
  };

  systemd.services.dex.restartTriggers = [
    config.age-template.files.dex-env.path
    config.age.secrets.blueberry-oauth2-proxy-client-secret.path
    config.age.secrets.kubernetes-oauth2-proxy-client-secret.path
    config.age.secrets.argocd-client-secret.path
  ];
}