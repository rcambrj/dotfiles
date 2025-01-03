{ lib, pkgs, perSystem, ... }: {
  home.packages = with pkgs; [
    gnomeExtensions.disable-3-finger-gestures
    perSystem.fusuma-plugin-appmatcher.appmatcher45
  ];

  dconf.settings = {
    "org/gnome/shell".enabled-extensions = [
      "disable-three-finger@lxp-git.github.com"
    ];
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-and-drag = false;
      tap-and-drag-lock = true;
      # this value depends on the udev hack for scroll speed in system touchpad.nix
      # but is there some clever maths? this number seems to suit for now
      # without hack => 0.0
      speed = lib.gvariant.mkDouble (1.0);
    };
  };

  services.fusuma = {
    enable = true;
    package = perSystem.fusuma.fusuma;
    extraPackages = [];
    settings = {
      tap = {
        "3" = {
          command = "${pkgs.ydotool}/bin/ydotool click 1";
        };
      };
      swipe = {
        "3" = {
          begin = {
            command = "${pkgs.ydotool}/bin/ydotool click 40";
            interval = "0.00";
          };
          update = {
            command = "${pkgs.ydotool}/bin/ydotool mousemove -- $move_x, $move_y";
            interval = "0.01";
            # this value depends on the udev hack for scroll speed in system touchpad.nix
            # but is there some clever maths? this number seems to suit for now
            # without hack => 1.20
            accel = "2.00";
          };
          end = {
            command = "${pkgs.ydotool}/bin/ydotool click 80";
          };
        };
      };
    };
  };
}