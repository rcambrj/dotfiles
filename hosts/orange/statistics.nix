{ config, ... }: {
  networking.firewall.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
  ];

  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        listenAddress = "192.168.142.200";
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };
    };
  };
}