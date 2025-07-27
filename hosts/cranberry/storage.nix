{ config, lib, pkgs, ... }: with lib; {
  networking.firewall.allowedTCPPorts = [
    (toInt (builtins.elemAt (strings.splitString ":" config.services.minio.listenAddress) 1))
    (toInt (builtins.elemAt (strings.splitString ":" config.services.minio.consoleAddress) 1))
  ];

  age.secrets.minio-root-pass.file  = ../../secrets/minio-root-pass.age;
  age.secrets.minio-ca-crt = {
    file = ../../secrets/minio-ca-crt.age;
    path = "${config.services.minio.certificatesDir}/CAs/ca.crt";
    owner = config.systemd.services.minio.serviceConfig.User;
    group = config.systemd.services.minio.serviceConfig.Group;
    mode = "444";
  };
  age.secrets.minio-key = {
    file = ./. + "/../../secrets/minio-${config.networking.hostName}-key.age";
    path = "${config.services.minio.certificatesDir}/private.key";
    owner = config.systemd.services.minio.serviceConfig.User;
    group = config.systemd.services.minio.serviceConfig.Group;
    mode = "400";
  };
  age.secrets.minio-crt = {
    file = ./. + "/../../secrets/minio-${config.networking.hostName}-crt.age";
    path = "${config.services.minio.certificatesDir}/public.crt";
    owner = config.systemd.services.minio.serviceConfig.User;
    group = config.systemd.services.minio.serviceConfig.Group;
    mode = "444";
  };

  # trust minio certificate authority system-wide
  # so that juicefs will connect without complaining
  # TODO: is this necessary?
  # security.pki.certificateFiles = [
  #   config.age.secrets.minio-ca-crt.path
  # ];

  age-template.files.minio-env = {
    vars = {
      pass = config.age.secrets.minio-root-pass.path;
    };
    content = ''
      MINIO_ROOT_USER=minioadmin
      MINIO_ROOT_PASSWORD=$pass
      MINIO_BROWSER_REDIRECT_URL="https://minio.home.cambridge.me"
    '';
  };

  services.minio = {
    enable = true;
    region = "home";
    rootCredentialsFile = config.age-template.files.minio-env.path;

    # TODO: listen on the kubernetes network (and change the proxy pod)
    # listenAddress = "10.42.0.1:9000";
    # consoleAddress = "10.42.0.1:9001";
  };
}