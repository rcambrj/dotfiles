{ config, flake, perSystem, pkgs, ... }: let
  firmwares = {
    # flash with firmware.bin on sd card
    btt-skr = pkgs.klipper-firmware.override {
      mcu = "btt-skr";
      firmwareConfig = ./klipper-btt-skr.config;
    };

    # flash with:
    # sudo dfu-util -l
    # sudo dfu-util -a 0 -s 0x08000000:mass-erase:force:leave -D /etc/klipper/firmwares/
    btt-ebb = pkgs.klipper-firmware.override {
      mcu = "btt-ebb";
      firmwareConfig = ./klipper-btt-ebb.config;
    };
    ucan = pkgs.klipper-firmware.override {
      mcu = "ucan";
      firmwareConfig = ./klipper-ucan.config;
    };
  };

  format = flake.lib.format-klipper pkgs;
in {
  environment.systemPackages = with pkgs; [
    dfu-util
    klipper-genconf # make menuconfig
    can-utils
    uhubctl # sudo uhubctl -a cycle -l 1-1 -p `grep "CAN adapter" | sed -En 's/^Bus [0-9]+ Device 0*([0-9]+):.*/\1/p'`
  ];

  environment.etc = {
    "klipper/firmwares/btt-skr".source = firmwares.btt-skr;
    "klipper/firmwares/btt-ebb".source = firmwares.btt-ebb;
    "klipper/firmwares/ucan".source = firmwares.ucan;
    "klipper/fluidd-config".source = perSystem.self.fluidd-config.overrideAttrs (attrs: {
      installPhase = attrs.installPhase + ''

          substituteInPlace $out/client.cfg \
          --replace-fail 'path: ~/printer_data/gcodes' 'path: ${config.services.moonraker.stateDir}/gcodes'
        '';
    });
    "klipper/printer.cfg".source = format.generate "klipper/printer.cfg" (
      (import ./printer.cfg.nix) //
      (import ./printer.level-gantry.cfg.nix) //
      {
        "include /etc/klipper/fluidd-config/client.cfg" = {};
      }
    );
  };

  services.klipper = {
    enable = true;
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    logFile = null; # log to stdout, rely on journald
    configDir = "${config.services.moonraker.stateDir}/config"; # use the same dir so that fluidd shows printer.cfg
    settings = {
      "include /etc/klipper/printer.cfg" = {};
    };
    firmwares = {
      # don't use this because it wants all MCUs to have a serial attr in services.klipper.settings
      # so not suitable for canbus or usb-to-can devices
    };
  };

  systemd.services.klipper.serviceConfig.Restart = "always";
}