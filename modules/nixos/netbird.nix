{ config, lib, perSystem, pkgs, ... }: with lib; {
  # configure PrivateKey first https://wg.orz.tools/ then
  # netbird up --setup-key=<setup key>
  age.secrets.netbird-private-key.file = ./. + "/../../secrets/${config.networking.hostName}-netbird-privatekey.age";

  age-template.files.netbird-secrets = {
    path = "/etc/${config.services.netbird.clients.default.dir.baseName}/config.d/60-secrets.json";
    vars = {
      privatekey = config.age.secrets.netbird-private-key.path;
    };
    content = ''
      {
        "PrivateKey": "$privatekey"
      }
    '';
  };

  # agentless => peer traffic broken: https://github.com/netbirdio/netbird/issues/5273
  # services.netbird.package = perSystem.nixpkgs-netbird.netbird;

  services.netbird = {
    useRoutingFeatures = "client";
    clients.default = {
      # default wireguard port 51820 for k3s flannel-wg
      port = 51821;
      openFirewall = true;
      interface = "netbird";
      hardened = false; # fails to bring up DNS route
      dns-resolver = {
        address = "127.0.0.62";
        port = mkDefault 53; # systemd-resolved only likes 53, errors otherwise

        # also add:
        # settings.Resolve = {
        #     DNS = "... 127.0.0.62";
        #     Domains = "... ~cambridge.netbird";
        # };
      };
    };
  };

  # don't delay network-online
  systemd.network.wait-online.ignoredInterfaces = [ config.services.netbird.clients.default.interface ];

  # protect the secrets in the config file
  systemd.services.netbird-default.serviceConfig.StateDirectoryMode = mkForce "0700";
}