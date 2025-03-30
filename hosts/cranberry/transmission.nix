{ config, pkgs, flake, lib, ... }: let
  toBase64 = import flake.nixosModules.toBase64 { inherit lib; };
  transmissionPkg = pkgs.transmission_4;

  group = import ./group.nix;

  rpc-username = "transmission";
  rpc-password = "password";
  base64-username-password = toBase64 "${rpc-username}:${rpc-password}";
in {
  services.transmission = {
    enable = true;
    package = transmissionPkg;
    openRPCPort = false;
    openPeerPorts = true;
    group = group;
    settings = {
      inherit rpc-username rpc-password;
      message-level = 5;
      port-forwarding-enabled = false;
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist = "127.0.0.1";
      rpc-host-whitelist = "transmission.media.cambridge.me";
      rpc-authentication-required = true;
      # with openPeerPorts this opens the whole range in nixos firewall
      # which is necessary as we don't know which port PIA will forward
      peer-port-random-on-start = true;
      peer-port-random-low = 16384;
      peer-port-random-high = 65535;
      download-dir = "/var/lib/media/downloads/transmission";

      # network speed and bandwidth
      peer-limit-global = 1000;
      peer-limit-per-torrent = 200;
      download-queue-size = 5;
      seed-queue-size = 100;
      speed-limit-down = 1000 * 50; # KB/s
      speed-limit-down-enabled = false;
      speed-limit-up = 1000 * 50; # KB/s
      speed-limit-up-enabled = true;

      # stop seeding at
      idle-seeding-limit = 60 * 24 * 7; # minutes
      idle-seeding-limit-enabled = true;
      ratio-limit = 10;
      ratio-limit-enabled = true;
    };
  };

  systemd.services.transmission = {
    after = [ "pia-vpn.service" ];
    bindsTo = [ "pia-vpn.service" ];
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  services.nginx.virtualHosts."transmission.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:9091";
      # basicAuthFile = config.age-template.files.transmission-htpasswd.path;
      extraConfig = ''
        proxy_set_header Authorization "Basic ${base64-username-password}";
      '';
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."transmission.media.cambridge.me" = {};

  age-template.files.transmission-rpc-env-auth = {
    vars = {
      # this doesnt need to be secure
    };
    content = ''
      TR_AUTH=${rpc-username}:${rpc-password}
    '';
  };

}