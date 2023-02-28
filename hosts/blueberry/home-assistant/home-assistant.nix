{ pkgs, ... }: let
  lldap-ha-auth = import ./lldap-ha-auth.nix { inherit pkgs; };
in {

  networking.firewall.allowedUDPPorts = [
    5353 # mDNS
  ];

  services.nginx.virtualHosts."home.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "home.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:8123";
    };
  };

  environment.systemPackages = [
    lldap-ha-auth
  ];

  services.postgresql.ensureDatabases = [ "hass" ];
  services.postgresql.ensureUsers = [{
    name = "hass";
    ensureDBOwnership = true;
  }];

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
    config = {
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
        db_url = "postgresql://@/hass";
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
        auth_providers = [
          {
            # https://github.com/lldap/lldap/blob/9ac96e8/example_configs/home-assistant.md
            type = "command_line";
            command = "${lldap-ha-auth}/bin/lldap-ha-auth";
            args = [
              "https://ldap.home.cambridge.me"
              "homeassistant_user"
              "homeassistant_admin"
            ];
            meta = true;
          }
          # keep enabled.
          # use admin user for long-lived tokens, eg. google-assistant
          { type = "homeassistant"; }
        ];
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      telegram_bot = [
        {
          platform = "broadcast";
          api_key = "!secret telegram_bot_api_key";
          allowed_chat_ids = [ "!secret telegram_group" ];
        }
      ];
      lovelace = {
        mode = "yaml";
      };
    };
  };
}