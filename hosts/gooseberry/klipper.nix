{ config, perSystem, pkgs, ... }: let
  # flash with:
  # sudo dfu-util -a 0 -s 0x08000000:mass-erase:force:leave -D /etc/klipper-firmwares/
  firmwares = {
    btt-skr = pkgs.klipper-firmware.override {
      mcu = "btt-skr";
      firmwareConfig = ./klipper-btt-skr.config;
    };
    btt-ebb = pkgs.klipper-firmware.override {
      mcu = "btt-ebb";
      firmwareConfig = ./klipper-btt-ebb.config;
    };
    ucan = pkgs.klipper-firmware.override {
      mcu = "ucan";
      firmwareConfig = ./klipper-ucan.config;
    };
  };
in {
  environment.systemPackages = with pkgs; [
    dfu-util
    klipper-genconf
  ];

  environment.etc = {
    fluidd-config = {
      source = perSystem.self.fluidd-config.overrideAttrs (attrs: {
        installPhase = attrs.installPhase + ''

            substituteInPlace $out/client.cfg \
            --replace-fail 'path: ~/printer_data/gcodes' 'path: ${config.services.moonraker.stateDir}/gcodes'
          '';
      });
    };
    "klipper-firmwares/btt-skr".source = firmwares.btt-skr;
    "klipper-firmwares/btt-ebb".source = firmwares.btt-ebb;
    "klipper-firmwares/ucan".source = firmwares.ucan;
  };

  services.klipper = {
    enable = true;
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    logFile = null; # log to stdout, rely on journald
    configDir = "${config.services.moonraker.stateDir}/config"; # use the same dir so that fluidd shows printer.cfg
    settings = {
      "include /etc/fluidd-config/client.cfg" = {};
    } // import ./printer.cfg.nix;
    firmwares = {
      # don't use this because it wants all MCUs to have a serial attr in services.klipper.settings
      # so not suitable for canbus or usb-to-can devices
    };
  };
}