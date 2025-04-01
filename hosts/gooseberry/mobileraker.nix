{ config, flake, ... }: {
  imports = [
    flake.nixosModules.mobileraker-companion
  ];

  services.mobileraker-companion = {
    enable = true;
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    settings = {
      "printer" = {
        moonraker_uri = "ws://127.0.0.1:7125/websocket";
        moonraker_api_key = false; # use trusted_clients for this instead
        snapshot_uri = "http://${config.services.ustreamer.listenAddress}/snapshot";
      };
    };
  };
}