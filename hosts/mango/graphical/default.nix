{ lib, pkgs, ... }: {
  imports = [
    ./brightness.nix
    ./touchpad.nix
  ];

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
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  security.pam.services.gdm-fingerprint.enableGnomeKeyring = true;

  # hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}