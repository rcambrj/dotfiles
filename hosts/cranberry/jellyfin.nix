{ pkgs, ... }: let
  group = import ./group.nix;
in {
  services.nginx.virtualHosts."jellyfin.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:30096";
    };
  };

  # environment.systemPackages = with pkgs; [
  #   jellyfin
  #   jellyfin-web
  #   jellyfin-ffmpeg
  # ];

  # services.jellyfin = {
  #   enable = true;
  #   group = group;
  # };

  # users.users.jellyfin.extraGroups = [ "render" ];
}