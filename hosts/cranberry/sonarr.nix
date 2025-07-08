{ ... }: let
  group = import ./group.nix;
in {
  # services.sonarr = {
  #   enable = true;
  #   group = group;
  # };

  # TODO: fix this once sonarr upgrades to dotnet 8 https://discourse.nixos.org/t/-/56828
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.428"
    "aspnetcore-runtime-6.0.36"
  ];

  services.nginx.virtualHosts."sonarr.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:30989";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."sonarr.media.cambridge.me" = {};
}