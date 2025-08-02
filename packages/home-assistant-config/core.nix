{ perSystem, pkgs, ... }: with pkgs.lib; {
  options = {
    "configuration.yaml" = mkOption {
      type = (pkgs.formats.yaml { }).type;
      default = {};
    };
    "ui-lovelace.yaml" = mkOption {
      type = (pkgs.formats.yaml { }).type;
      default = {};
    };
  };
  config."configuration.yaml" = {
    # don't enable default_config, instead enumerate individual features
    # https://www.home-assistant.io/integrations/default_config/
    # assist_pipeline = {};
    # backup = {};
    bluetooth = {}; # required for esphome
    config = {};
    # conversation = {};
    dhcp = {};
    # energy = {};
    history = {};
    # homeassistant_alerts = {};
    cloud = {}; # required for google-home
    # image_upload = {};
    logbook = {};
    # media_source = {};
    mobile_app = {};
    # my = {};
    # ssdp = {};
    # stream = {};
    sun = {};
    usb = {}; # required for esphome
    webhook = {};
    # zeroconf = {}; # device discovery (enable temporarily to add homekit/mDNS devices)

    recorder = {
      # in-memory recorder is no longer supported
      # db_url = "postgresql://@postgres/hass";
      # setting purge_keep_days to 0 will error
      purge_keep_days = 1;
      exclude = {
        entity_globs = [ "*" ];
      };
    };
    logbook = {
      exclude = {
        entity_globs = [ "*" ];
      };
    };
    homeassistant = {
      unit_system = "metric";
      time_zone = "Europe/Amsterdam";
      country = "NL";
      internal_url = "https://home.cambridge.me";
      external_url = "https://home.cambridge.me";
    };
    http = {
      use_x_forwarded_for = true;
      trusted_proxies = [
        "10.42.0.0/16"
        "127.0.0.1"
        "::1"
      ];
    };
    lovelace = {
      mode = "yaml";
    };
  };
}