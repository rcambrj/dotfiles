{ config, lib, ... }: {
  options.services.avahi-reflector.enable =
    lib.mkEnableOption "Avahi mDNS reflector for Kubernetes pods";

  config = lib.mkIf config.services.avahi-reflector.enable {
    services.avahi = {
      enable = true;
      reflector = true;
      openFirewall = true;
    };
  };
}
