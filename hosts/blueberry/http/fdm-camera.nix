{ config, ... }: {
  # do https termination here instead of on raspi3 because the latter lacks aes hw offload
  # configure these URLs in fluidd:
  # https://user:<password>@fdm-camera.home.cambridge.me/stream
  # https://user:<password>@fdm-camera.home.cambridge.me/snapshot


  environment.etc.fdm-camera-basic-auth = {
    text = ''
      user:$apr1$ml.4JaRX$Uz.5TseJ/4BlA4/Dzv9yN1
    '';
  };

  services.nginx.virtualHosts."fdm-camera.home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";

    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://fdm.cambridge.me:22678";
      basicAuthFile = "/etc/fdm-camera-basic-auth";
    };
  };
}