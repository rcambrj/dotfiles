{ lib, pkgs, ... }: {
  home.packages = with pkgs; [
    gnomeExtensions.dash-to-panel
  ];

  # inspired by:
  # https://github.com/Electrostasy/dots/blob/c62895040a8474bba8c4d48828665cfc1791c711/profiles/system/gnome/default.nix
  dconf = {
    enable = true;
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
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
      };
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
        # TODO: these have no impact
        # https://github.com/GNOME/gsettings-desktop-schemas/blob/3115114430dbef644294f4818fe6a4512fb4e43d/headers/gdesktop-enums.h#L245
        font-hinting = "full";
        font-antialiasing = "rgba";
      };
      "org/gnome/desktop/notifications" = {
        show-in-lock-screen = false;
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        allow-extension-installation = false;
        favorite-apps = [
          "org.gnome.Settings.desktop"
          "1password.desktop"
          "org.gnome.Console.desktop"
          "code.desktop"
          "firefox.desktop"
          "spotify.desktop"
          "slack.desktop"
          "com.github.xeco23.WasIstLos.desktop"
          "org.telegram.desktop.desktop"
        ];
        enabled-extensions = [
          "appmatcher45@iberianpig.dev"
          # "apps-menu@gnome-shell-extensions.gcampax.github.com"
          # "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
          "dash-to-panel@jderose9.github.com"
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
          # "light-style@gnome-shell-extensions.gcampax.github.com"
          # "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
          # "status-icons@gnome-shell-extensions.gcampax.github.com"
          "system-monitor@gnome-shell-extensions.gcampax.github.com"
          # "user-theme@gnome-shell-extensions.gcampax.github.com"
          # "window-list@gnome-shell-extensions.gcampax.github.com'"
          # "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
          # "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        ];
      };
      "org/gnome/shell/extensions/dash-to-panel" = {
        # https://github.com/home-sweet-gnome/dash-to-panel/blob/cccbdcdaa23cb718fa5b72094c2f46420adcfabf/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.xml
        multi-monitors = false;
        panel-element-positions-monitors-sync = true;
        position = "BOTTOM";
        panel-sizes = [
          (lib.gvariant.mkDictionaryEntry "default" (lib.gvariant.mkInt32 48))
        ];
        show-activities-button = false;
        showdesktop-button-width = lib.gvariant.mkInt32 0;
        dot-style-focused = "DOTS";
        dot-style-unfocused = "DOTS";
        hide-overview-on-startup = true;
        # TODO: order of items. what are the values?
        # panel-element-positions =
        tray-size = lib.gvariant.mkInt32 16; # font size
        leftbox-size = lib.gvariant.mkInt32 16; # font size
        appicon-margin = lib.gvariant.mkInt32 4;
        appicon-padding = lib.gvariant.mkInt32 4;
        tray-padding = lib.gvariant.mkInt32 0;
        leftbox-padding = lib.gvariant.mkInt32 0;
        status-icon-padding = lib.gvariant.mkInt32 0;
      };
    };
  };
}