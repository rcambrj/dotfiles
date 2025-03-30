{ config, flake, pkgs, ... }: {
  services.nginx.virtualHosts."grafana.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}";
    };
  };

  age-template.files.grafana-ldap-password = {
    vars = {
      ldap_admin_password = config.age.secrets.ldap-admin-ro-password.path;
    };
    content = "$ldap_admin_password";
    owner = "grafana";
    group = "grafana";
  };

  age-template.files.grafana-influxdb-secure-data = {
    vars = {
      influxdb_token = config.age.secrets.influxdb-admin-token.path;
    };
    content = ''$influxdb_token'';
    owner = "grafana";
    group = "grafana";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 4723;
        root_url = "https://grafana.home.cambridge.me";
      };
      security = {
        disable_initial_admin_creation = true;
        secret_key = "$__file{${config.age.secrets.grafana-secret.path}}";
      };
      "auth.basic" = {
        enabled = false;
      };
      "auth.ldap" = {
        enabled = true;
        config_file = toString ((pkgs.formats.toml { }).generate "grafana-ldap.toml" {
          servers = [{
            host = "ldap.home.cambridge.me";
            port = 6360;
            use_ssl = true;
            root_ca_cert = flake.lib.ldap-cert;
            bind_dn = "uid=admin-ro,ou=people,dc=cambridge,dc=me";
            bind_password = "$__file{${config.age-template.files.grafana-ldap-password.path}}";
            search_filter = "(&(uid=%s)(memberof=cn=grafana,ou=groups,dc=cambridge,dc=me))";
            search_base_dns = ["dc=cambridge,dc=me"];
            attributes = {
              member_of = "memberof";
              email = "mail";
              name = "displayName";
              username = "uid";
            };
            group_mappings = [
              {
                group_dn = "cn=grafana_admin,ou=groups,dc=cambridge,dc=me";
                org_role = "Admin";
                grafana_admin = true;
              }
              {
                group_dn = "cn=grafana_editor,ou=groups,dc=cambridge,dc=me";
                org_role = "Editor";
              }
              {
                group_dn = "cn=grafana_viewer,ou=groups,dc=cambridge,dc=me";
                org_role = "Viewer";
              }
            ];
          }];
        });
      };
    };
    provision.datasources.settings = {
      apiVersion = 1;

      datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
        # {
        #   name = "Loki";
        #   type = "loki";
        #   url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
        # }
        {
          default = true;
          name = "InfluxDB-Flux";
          type = "influxdb";
          url = "http://localhost:8086";
          jsonData = {
            version = "Flux";
            organization = "main";
          };
          secureJsonData = {
            token = "$__file{${config.age-template.files.grafana-influxdb-secure-data.path}}";
          };
        }
      ];
    };
  };
}