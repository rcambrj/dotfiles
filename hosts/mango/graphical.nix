{ lib, pkgs, ... }: {
  boot = {
    loader.timeout = 1;
    plymouth = {
      enable = true;
      theme = "flame";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "flame" ];
        })
      ];
    };
  };

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  # security.pam.services.gdm-fingerprint.enableGnomeKeyring = true;
  # security.pam.services.gdm.enableGnomeKeyring = true;
  # environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID";

  environment.systemPackages = with pkgs; [
    gnomeExtensions.brightness-control-using-ddcutil
    ddcutil
  ];
  # https://github.com/NixOS/nixpkgs/blob/72f492e275fc29d44b3a4daf952fbeffc4aed5b8/nixos/modules/services/x11/desktop-managers/plasma5.nix#L257
  boot.kernelModules = [ "i2c-dev" ]; # for ddc
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", TAG+="uaccess"
  '';

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
  #
  # inspired by:
  # https://github.com/Electrostasy/dots/blob/c62895040a8474bba8c4d48828665cfc1791c711/profiles/system/gnome/default.nix
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
        "org/gnome/desktop/interface" = {
          font-hinting = "full";
        };
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = [
            "status-icons@gnome-shell-extensions.gcampax.github.com"
            "system-monitor@gnome-shell-extensions.gcampax.github.com"
            # "window-list@gnome-shell-extensions.gcampax.github.com"
            "drive-menu@gnome-shell-extensions.gcampax.github.com"

            "display-brightness-ddcutil@themightydeity.github.com"
          ];
        };
        "org/gnome/shell/extensions/display-brightness-ddcutil" = {
          # TODO: these probably don't work.
          show-all-slider = true;
          show-internal-slider = true;
          only-all-slider = false;
          show-value-label = false;
          show-display-name = false;
          show-osd = true;
          show-sliders-in-submenu = false;
          button-location = lib.gvariant.mkUint16 1; # 0=menu bar, 1=system menu
          step-change-keyboard = lib.gvariant.mkDouble (5.0);
          disable-display-state-check = true;
        };
      };
    }];
  };
}