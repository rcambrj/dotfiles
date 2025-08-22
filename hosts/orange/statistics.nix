{ config, ... }: {
  # only permit on wt0
  networking.firewall.interfaces.nb-default.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
  ];

  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };
    };
  };
}