{ config, ... }: {
  age.secrets.netbird-private-key.file = ./. + "/../../secrets/${config.networking.hostName}-netbird-privatekey.age";

  age-template.files.telegraf-env = {
    path = "/etc/${config.services.netbird.clients.default.dir.baseName}/config.d/60-secrets.json";
    owner = config.services.netbird.clients.default.user.name;
    group = config.services.netbird.clients.default.user.group;
    vars = {
      privatekey = config.age.secrets.netbird-private-key.path;
    };
    content = ''
      {
        "PrivateKey": "$privatekey",
      }
    '';
  };


  services.netbird.clients.default = {
    port = 51820;
    openFirewall = true;
    config = {
      # DNS is provided by router
      DisableDNS = true;
    };
  };

  services.resolved = {
    enable = true;
    extraConfig = ''
      [Resolve]
      DNS=192.168.142.1
      Domains=~cambridge.me
    '';
  };
}