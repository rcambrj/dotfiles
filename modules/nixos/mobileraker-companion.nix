# inspired by:
# https://github.com/truelecter/hive/blob/76c16b8ddc9c5f24378bf090d7470c2812570517/cells/klipper/modules/mobileraker-companion.nix
#
{
  config,
  flake,
  lib,
  pkgs,
  perSystem,
  ...
}:
with lib; let
  cfg = config.services.mobileraker-companion;

  format = flake.lib.format-klipper pkgs;
in {
  options.services.mobileraker-companion = {
    enable = mkEnableOption "Companion for mobileraker, enabling push notification.";

    package = mkOption {
      type = types.package;
      default = perSystem.self.mobileraker-companion;
      defaultText = literalExpression "pkgs.mobileraker-companion";
      description = lib.mdDoc "The mobileraker-companion package.";
    };

    user = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
        User account under which mobileraker-companion runs.
        If null is specified (default), a temporary user will be created by systemd.
      '';
    };

    group = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
        Group account under which mobileraker-companion runs.
        If null is specified (default), a temporary user will be created by systemd.
      '';
    };

    settings = mkOption {
      type = format.type;
      default = {};
      description = lib.mdDoc ''
        Configuration for mobileraker-companion. See the [documentation](https://github.com/Clon1998/mobileraker_companion#companion---config)
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable (let
    settingsFile = format.generate "mobileraker-companion.cfg" cfg.settings;
  in {
    assertions = [
      {
        assertion = cfg.enable -> config.services.moonraker.enable;
        message = "mobileraker-companion requires Moonraker to be enabled on this system. Please enable services.moonraker to use it.";
      }
      {
        assertion = cfg.user != null -> cfg.group != null;
        message = "Option mobileraker-companion.group is not set when a user is specified.";
      }
    ];

    systemd.services.mobileraker-companion = {
      description = "Companion for mobileraker, enabling push notification.";

      after = ["moonraker.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/mobileraker-companion --configfile /etc/mobileraker-companion.cfg";
        Group = cfg.group;
        User = cfg.user;
      };

      restartTriggers = [
        "${settingsFile}"
      ];
    };

    users = lib.optionalAttrs (cfg.user != null) {
      users.${cfg.user} = {
        isSystemUser = true;

        group = cfg.group;

        extraGroups = ["tty"];
      };
      groups.${cfg.group} = {};
    };

    environment.etc."mobileraker-companion.cfg".source = settingsFile;
  });
}
