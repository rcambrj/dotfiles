{ config, lib, pkgs, ... }: with lib; {
  networking.firewall.allowedTCPPorts = [
    (toInt (builtins.elemAt (strings.splitString ":" config.services.minio.listenAddress) 1))
    (toInt (builtins.elemAt (strings.splitString ":" config.services.minio.consoleAddress) 1))
  ];

  age.secrets.minio-secret-key.file = ../../secrets/minio-secret-key.age;
  age.secrets.minio-access-key.file = ../../secrets/minio-access-key.age;
  age.secrets.minio-root-pass.file = ../../secrets/minio-root-pass.age;

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
    accessKey = config.age.secrets.minio-access-key.path; # 8-40 chars
    secretKey = config.age.secrets.minio-secret-key.path; # 8-40 chars
    rootCredentialsFile = config.age-template.files.minio-env.path;

    # TODO: listen on the kubernetes network (and change the proxy pod)
    # listenAddress = "10.42.0.1:9000";
    # consoleAddress = "10.42.0.1:9001";
  };
}