{ ... }: {
  services.nginx.virtualHosts."wan-status.router.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "router.cambridge.me";
    locations."/" = {
      root = "/run/wan-status";
      index = "index.txt";
    };
  };
}