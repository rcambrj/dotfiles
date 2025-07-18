#
# this machine is used for running the home's automation
# * home assistant
# * esphome
#
{ flake, inputs, ... }: {
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.bare-metal
    flake.nixosModules.config-intel
    flake.nixosModules.server-backup
    flake.nixosModules.telemetry
    inputs.agenix-template.nixosModules.default
    ./esphome.nix
    ./downloads-enabled.nix
    ./home-assistant
    ./http
    ./auth
    ./postgres.nix
    ./telemetry
  ];

  networking.hostName = "blueberry";


  age.secrets = {
    acme-cloudflare.file = ../../secrets/acme-cloudflare.age;
    home-assistant = {
      file = ../../secrets/home-assistant.age;
      path = "/var/lib/hass/secrets.yaml";
      owner = "hass";
      group = "hass";
    };
    webos-dev-mode-curl = {
      file = ../../secrets/webos-dev-mode-curl.age;
      owner = "hass";
      group = "hass";
    };
    backup-bucket = {
      file = ../../secrets/blueberry-backup-bucket.age;
    };
    backup-credentials = {
      file = ../../secrets/blueberry-backup-credentials.age;
    };
    backup-encryption-key = {
      file = ../../secrets/blueberry-backup-encryption-key.age;
    };
    blueberry-pgadmin = {
      file = ../../secrets/blueberry-pgadmin.age;
    };
    lldap-jwt-secret = {
      file = ../../secrets/lldap-jwt-secret.age;
      owner = "lldap";
      group = "lldap";
    };
    lldap-cert-key = {
      file = ../../secrets/lldap-cert-key.age;
      owner = "lldap";
      group = "lldap";
    };
    lldap-env = {
      file = ../../secrets/lldap-env.age;
    };
    ldap-admin-ro-password = {
      file = ../../secrets/ldap-admin-ro-password.age;
    };
    blueberry-oauth2-proxy-client-secret = {
      file = ../../secrets/blueberry-oauth2-proxy-client-secret.age;
    };
    kubernetes-oauth2-proxy-client-secret = {
      file = ../../secrets/kubernetes-oauth2-proxy-client-secret.age;
    };
    blueberry-oauth2-proxy-cookie-secret = {
      file = ../../secrets/blueberry-oauth2-proxy-cookie-secret.age;
    };
    argocd-client-secret = {
      file = ../../secrets/argocd-client-secret.age;
    };
    grafana-secret = {
      file = ../../secrets/grafana-secret.age;
      owner = "grafana";
      group = "grafana";
    };
    influxdb-admin-password = {
      file = ../../secrets/influxdb-admin-password.age;
      owner = "influxdb2";
      group = "influxdb2";
    };
    influxdb-admin-token = {
      file = ../../secrets/influxdb-admin-token.age;
      owner = "influxdb2";
      group = "influxdb2";
    };
  };

  fileSystems = {
    "/var/lib" = {
      device = "/dev/disk/by-label/NIXOSSTATE";
      fsType = "ext4";
      neededForBoot = true;
    };
  };

  services.mbpfan.enable = true;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "powersave";
        energy_performance_preference = "power";
        turbo = "never";
      };
    };
  };
}
