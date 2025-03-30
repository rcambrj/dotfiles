{ perSystem, config, ... }: {
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
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    logFile = "/dev/null"; # disable logging to disk, rely on journald
    configDir = "${config.services.moonraker.stateDir}/config"; # use the same dir so that fluidd shows printer.cfg
    settings = {
      "include /etc/fluidd-config/client.cfg" = {};
    } // import ./printer.cfg.nix;
  };
}