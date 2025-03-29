{ ... }: {
  services.fluidd = {
    enable = true;
    hostName = "fdm.cambridge.me";
    nginx = {
      serverAliases = ["www.fdm.cambridge.me"];
      forceSSL = true;
      useACMEHost = "fdm.cambridge.me";
    };
  };
}