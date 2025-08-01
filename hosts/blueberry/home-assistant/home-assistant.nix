{ config, perSystem, pkgs, ... }: {

  networking.firewall.allowedUDPPorts = [
    5353 # mDNS
  ];

  services.postgresql.ensureDatabases = [ "hass" ];
  services.postgresql.ensureUsers = [{
    name = "hass";
    ensureDBOwnership = true;
  }];

  age-template.files.webos-dev-mode-curl = {
    path = "/run/home-assistant/webos-dev-mode-curl.env";
    vars = {
      token = config.age.secrets.webos-dev-mode-token.path;
    };
    content = ''
      url=https://developer.lge.com/secure/ResetDevModeSession.dev?sessionToken=$token
    '';
    owner = "hass";
    group = "hass";
  };

  services.home-assistant = {
    enable = true;
    package = (pkgs.home-assistant.override { extraPackages = python3Packages: with python3Packages; [
      psycopg2 # postgres
      zigpy-deconz
    ]; });
    extraComponents = [
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
      # "met" # No module named 'metno' - part of default_config
      # "radio_browser" # No module named 'radios' - part of default_config
      # "google_translate" # No module named 'gtts' - part of default_config
      "esphome"
      "default_config" # only includes packages, does not enable in configuration.yaml
      "zha" # zigbee home assistant
      "homekit_controller" # homekit device discovery (somfy tahoma)
    ];
    config = perSystem.self.home-assistant-config.passthru."home-assistant.yaml";
    lovelaceConfigWritable = true;
    lovelaceConfig = perSystem.self.home-assistant-config.passthru."ui-lovelace.yaml";
  };
}