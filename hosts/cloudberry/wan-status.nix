{ ... }: {
  services.nginx.virtualHosts."wan-status.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      root = "/var/run/wan-status";
      index = "index.txt";
    };
  };
}