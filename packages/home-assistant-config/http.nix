{ pkgs, ... }: {
  options.".storage/http" = pkgs.lib.mkOption {
    type = (pkgs.formats.json { }).type;
    default = {};
  };

  config.".storage/http" = {
    version = 2;
    minor_version = 2;
    key = "http";
    data = {
      stable = {
        server_port = 8123;
        cors_allowed_origins = [ "https://cast.home-assistant.io" ];
        login_attempts_threshold = -1;
        ip_ban_enabled = true;
        ssl_profile = "modern";
        use_x_frame_options = true;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "10.42.0.0/16"
          "127.0.0.0/32"
          "::1/128"
        ];
        created_at = "1970-01-01T00:00:00+00:00";
        error = null;
        error_message = null;
      };
      pending = null;
      yaml_migration_done = true;
    };
  };
}
