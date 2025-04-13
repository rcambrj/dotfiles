{ config, ... }: {


  environment.etc.fdm-camera-basic-auth = {
    text = ''
      user:$apr1$ml.4JaRX$Uz.5TseJ/4BlA4/Dzv9yN1
    '';
  };

  services.nginx.virtualHosts."fdm.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "fdm.cambridge.me";

    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "https://elderberry.cambridge.me";
    };

    locations."/webcam/" = {
      # do https termination here instead of on raspi3
      # because the raspi3 lacks aes hw offload
      # yes, the camera stream is public on the lan
      # configure these URLs in fluidd:
      # https://user:<password>@fdm.cambridge.me/webcam/stream
      # https://user:<password>@fdm.cambridge.me/webcam/snapshot
      proxyWebsockets = true;
      proxyPass = "http://elderberry.cambridge.me:22678/";
      basicAuthFile = "/etc/fdm-camera-basic-auth";
    };
  };
}