{ config, ... }: {
  age.secrets.patroni-replication-password.file = ../../secrets/patroni-replication-password.age;
  age.secrets.patroni-superuser-password.file = ../../secrets/patroni-superuser-password.age;


  networking.firewall.allowedTCPPorts = [
    config.services.patroni.restApiPort
    config.services.patroni.postgresqlPort
  ];

  services.patroni = {
    enable = true;
    environmentFiles = {
      PATRONI_REPLICATION_PASSWORD = config.age.secrets.patroni-replication-password.path;
      PATRONI_SUPERUSER_PASSWORD = config.age.secrets.patroni-superuser-password.path;
    };
    softwareWatchdog = true;
    settings = {};
    scope = "home";
    name = config.networking.hostName;
    nodeIp = "192.168.142.20";
    otherNodesIps = [];
  };
}