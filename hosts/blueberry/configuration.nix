#
# this machine is a kubernetes node
#
{ flake, inputs, ... }: {
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
    inputs.agenix-template.nixosModules.default

    flake.nixosModules.access-server
    flake.nixosModules.bare-metal
    flake.nixosModules.base
    flake.nixosModules.common
    flake.nixosModules.config-intel
    flake.nixosModules.gpu-intel
    flake.nixosModules.server-backup
    flake.nixosModules.telemetry

    ./esphome.nix
    ./downloads-enabled.nix
    ./postgres.nix
    ./telemetry
    ./node.nix
  ];

  networking.hostName = "blueberry";

  facter.detected = {
    # wifi driver broadcom-sta-6.30.223.271-57-6.12.39 is compromised
    # not needed anyway, stop facter installing it
    networking.broadcom.sta.enable = false;
  };

  age.secrets = {
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
    ldap-admin-ro-password = {
      file = ../../secrets/ldap-admin-ro-password.age;
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
