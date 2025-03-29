{ perSystem, config, ... }: {
  users.users.klipper = {
    # use a UID not likely to conflict with this machine's services
    uid = config.ids.uids.sickbeard;
    group = "klipper";
  };
  users.groups.klipper = {
    # use the moonraker GID since klipper doesnt have one
    gid = config.ids.gids.moonraker;
  };

  environment.etc = {
    fluidd-config = {
      source = perSystem.self.fluidd-config.overrideAttrs (attrs: {
        installPhase = attrs.installPhase + ''

            substituteInPlace $out/client.cfg \
            --replace-fail 'path: ~/printer_data/gcodes' 'path: ${config.services.moonraker.stateDir}/gcodes'
          '';
      });
    };
  };

  services.klipper = {
    enable = true;
    user = "klipper";
    group = "klipper";
    logFile = "/dev/null"; # rely on journald
    settings = {
      "include /etc/fluidd-config/client.cfg" = {};
    } // import ./printer.cfg.nix;
  };
}