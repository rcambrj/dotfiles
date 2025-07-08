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

  boot.kernelParams = [ "i915.enable_guc=2" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };
  environment.systemPackages = with pkgs; [
    # jellyfin
    # jellyfin-web
    # jellyfin-ffmpeg
    intel-gpu-tools
    intel-media-sdk
    intel-compute-runtime
    libva-utils
  ];

  # services.jellyfin = {
  #   enable = true;
  #   group = group;
  # };

  # users.users.jellyfin.extraGroups = [ "render" ];
}