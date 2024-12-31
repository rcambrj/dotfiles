{ lib, pkgs, ... }: {
  boot = {
    loader.timeout = 1;
    plymouth = {
      enable = true;
      theme = "flame";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "flame" ];
        })
      ];
    };
  };

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  fonts.fontconfig = {
    enable = true;
    hinting.style = "none";
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  # security.pam.services.gdm-fingerprint.enableGnomeKeyring = true;
  # security.pam.services.gdm.enableGnomeKeyring = true;
  # environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID";

  environment.systemPackages = with pkgs; [
    gnomeExtensions.brightness-control-using-ddcutil
  ];

  # gsettings list-recursively
  # gsettings range org.gnome.desktop.wm.preferences num-workspaces
  # arrayOf
  # maybeOf
  # tupleOf
  # dictionaryEntryOf
  # string = "s";
  # boolean = "b";
  # uchar = "y";
  # int16 = "n";
  # uint16 = "q";
  # int32 = "i";
  # uint32 = "u";
  # int64 = "x";
  # uint64 = "t";
  # double = "d";
  # variant = "v";
  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          clock-show-weekday = true;
          show-battery-percentage = true;
        };
        "org/gnome/desktop/wm/preferences" = {
          num-workspaces = lib.gvariant.mkInt32 1;
          audible-bell = false;
        };
        "org/gnome/shell".enabled-extensions = [
          "display-brightness-ddcutil@themightydeity.github.com"
        ];
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-and-drag = false;
          tap-and-drag-lock = true;
        };
        "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
        "org/gnome/nautilus/list-view" = {
          use-tree-view = true;
          default-zoom-level = "small";
        };
        "org/gtk/gtk4/settings/file-chooser" = {
          sort-directories-first = true;
          show-hidden = true;
          view-type = "list";
        };
        "org/gnome/shell/keybindings" = {
          toggle-overview = [ "<Control>Space" ];
        };
      };
    }];
  };
}