{ lib, pkgs, ... }: {
  home.packages = with pkgs; [
    gnomeExtensions.brightness-control-using-ddcutil
  ];

  dconf.settings = {
    "org/gnome/shell".enabled-extensions = [
      "display-brightness-ddcutil@themightydeity.github.com"
    ];
    "org/gnome/shell/extensions/display-brightness-ddcutil" = {
      show-all-slider = true;
      show-internal-slider = true;
      only-all-slider = false;
      show-value-label = false;
      show-display-name = false;
      show-osd = true;
      show-sliders-in-submenu = false;
      button-location = lib.gvariant.mkInt32 1; # 0=menu bar, 1=system menu
      step-change-keyboard = lib.gvariant.mkDouble (5.0);
      disable-display-state-check = true;
    };
  };
}