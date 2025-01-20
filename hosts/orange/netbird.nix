{ ... }: {
  networking.firewall = {
    allowedTCPPorts = [
      51820
    ];
    allowedUDPPorts = [
      51820
    ];
  };
  services.netbird = {
    enable = true;
  };
}