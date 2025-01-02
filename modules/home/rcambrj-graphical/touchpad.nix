{ pkgs, perSystem, ... }: {
  home.packages = [
    perSystem.fusuma-plugin-appmatcher.appmatcher45
  ];

  services.fusuma = {
    enable = true;
    package = perSystem.fusuma.fusuma;
    extraPackages = [];
    settings = {
      swipe = {
        "3" = {
          begin = {
            command = "${pkgs.ydotool}/bin/ydotool click 40";
            interval = "0.00";
          };
          update = {
            command = "${pkgs.ydotool}/bin/ydotool mousemove -- $move_x, $move_y";
            interval = "0.01";
            accel = "1.20";
          };
          end = {
            command = "${pkgs.ydotool}/bin/ydotool click 80";
          };
        };
      };
    };
  };
}