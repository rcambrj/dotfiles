{ config, lib, pkgs, ... }:
with lib;
let
in {
  age.secrets = {
    cloudflare-token.file = ../../secrets/cloudflare-token.age;
    cloudflare-zone-id.file = ../../secrets/cloudflare-zone-id.age;
    cloudflare-ddns-host.file = ../../secrets/cloudflare-ddns-host.age;
  };

  age-template.files.ddns-updater = {
    vars = {
      token = config.age.secrets.cloudflare-token.path;
      zoneid = config.age.secrets.cloudflare-zone-id.path;
      domain = config.age.secrets.cloudflare-ddns-host.path;
    };
    content = ''
      {
        "settings": [
          {
            "provider": "cloudflare",
            "zone_identifier": "$zoneid",
            "domain": "$domain",
            "ttl": 600,
            "token": "$token",
            "ip_version": "ipv4",
            "ipv6_suffix": ""
          }
        ]
      }
    '';
    owner = config.systemd.services.ddns-updater.serviceConfig.User;
    group = config.systemd.services.ddns-updater.serviceConfig.Group;
  };

  users.groups.ddns-updater = {};
  users.users.ddns-updater = {
    isSystemUser = true;
    group = "ddns-updater";
  };

  services.ddns-updater = {
    enable = true;
    environment = {
      PERIOD = "1m";
      SERVER_ENABLED = "no";
      RESOLVER_ADDRESS = "1.1.1.1:53";
      CONFIG_FILEPATH = config.age-template.files.ddns-updater.path;
    };
  };

  systemd.services.ddns-updater = {
    serviceConfig = {
      DynamicUser = true;
      User = "ddns-updater";
      Group = "ddns-updater";
   };
  };
}