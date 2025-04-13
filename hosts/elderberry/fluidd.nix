{ ... }: {
  services.fluidd = {
    enable = true;
    hostName = "elderberry.cambridge.me";
    nginx = {
      serverAliases = ["www.elderberry.cambridge.me"];
      forceSSL = true;
      useACMEHost = "elderberry.cambridge.me";
    };
  };
}