{ ... }: {
  services.fluidd = {
    enable = true;
    hostName = "gooseberry.cambridge.me";
    nginx = {
      serverAliases = ["www.gooseberry.cambridge.me"];
      forceSSL = true;
      useACMEHost = "gooseberry.cambridge.me";
    };
  };
}