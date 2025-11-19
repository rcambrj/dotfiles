#
# netbird-default up --management-url https://netbird.cambridge.me --setup-key ...
#
{ config, inputs, lib, pkgs, ... }:
with lib;
let
  externalDomain = "netbird.cambridge.me";
  internalDomain = "cambridge.netbird";
  datastoreKeyFile = config.age.secrets.netbird-datastore-key.path;
  turnPasswordFile = config.age.secrets.netbird-coturn-password.path;
  turnSecretFile = config.age.secrets.netbird-coturn-secret.path;

  issuer = "https://cambridge.eu.auth0.com";
  # consumer facing auth
  clientId = "4UZs4FOtOD7VhMQFpinXPfcs00al9luh";
  clientSecret = "qgTL6vPoVBc5WoNSOfslEWdsWll4k3gsjODC34TQUQARiqVXRqPtofnmJ66E9NSQ";
  audience = clientId;
  # netbird <> auth0 (machine to machine) auth
  mgmtClientIdFile = config.age.secrets.netbird-mgmt-client-id.path;
  mgmtClientSecretFile = config.age.secrets.netbird-mgmt-client-secret.path;
  mgmtAudience = "${issuer}/api/v2/";
in {
  age.secrets = {
    netbird-datastore-key.file = ../../secrets/netbird-datastore-key.age;
    netbird-mgmt-client-id.file = ../../secrets/netbird-mgmt-client-id.age;
    netbird-mgmt-client-secret.file = ../../secrets/netbird-mgmt-client-secret.age;
    netbird-coturn-password = {
      file = ../../secrets/netbird-coturn-password.age;
      owner = "turnserver"; # netbird also needs access but runs as root
      group = "turnserver"; # netbird also needs access but runs as root
    };
    netbird-coturn-secret = {
      file = ../../secrets/netbird-coturn-secret.age;
      owner = "turnserver"; # netbird also needs access but runs as root
      group = "turnserver"; # netbird also needs access but runs as root
    };
  };

  services.netbird.server = {
    enable = true;
    domain = "netbird.cambridge.me";
    enableNginx = true;
    management = {
      dnsDomain = internalDomain;
      singleAccountModeDomain = internalDomain;
      disableAnonymousMetrics = true;
      oidcConfigEndpoint = "${issuer}/.well-known/openid-configuration";
      settings = {
        DataStoreEncryptionKey._secret = datastoreKeyFile;
        HttpConfig = {
          AuthAudience = audience;
        };
        IdpManagerConfig = {
          ManagerType = "auth0";
          ClientConfig = {
            Issuer = issuer;
            ClientID._secret = mgmtClientIdFile;
            ClientSecret._secret = mgmtClientSecretFile;
            GrantType = "client_credentials";
          };
          ExtraConfig.Audience = mgmtAudience;
        };
        DeviceAuthorizationFlow = {
          ProviderConfig = {
            Audience = audience;
            ClientID = clientId;
            ClientSecret = clientSecret;
            DeviceAuthEndpoint = "${issuer}/oauth/device/code";
            Domain = issuer;
            TokenEndpoint = "${issuer}/oauth/token";
            UseIDToken = true;
          };
        };
        PKCEAuthorizationFlow = {
          ProviderConfig = {
            Audience = audience;
            ClientID = clientId;
            ClientSecret = clientSecret;
            AuthorizationEndpoint = "${issuer}/authorize";
            TokenEndpoint = "${issuer}/oauth/token";
            UseIDToken = true;
          };
        };
        Stuns = [
          {
            Proto = "udp";
            URI = "stun:${externalDomain}:3478";
            Username = "netbird";
            Password._secret = turnPasswordFile;
          }
        ];
        TURNConfig = {
          Secret._secret = turnSecretFile;
        };
      };
    };
    coturn = {
      enable = true;
      user = "netbird";
      passwordFile = turnPasswordFile;
      useAcmeCertificates = true;
    };
    signal = {
      enable = true;
    };
    dashboard = {
      settings = {
        USE_AUTH0 = true;
        AUTH_AUDIENCE = audience;
        AUTH_AUTHORITY = issuer;
        AUTH_CLIENT_ID = clientId;
        AUTH_SUPPORTED_SCOPES="openid profile email api email_verified";
        AUTH_CLIENT_SECRET = mkForce clientSecret;
      };
    };
  };

  services.nginx.virtualHosts."${externalDomain}" = {
    addSSL = true;
    useACMEHost = "netbird.cambridge.me";
  };
}