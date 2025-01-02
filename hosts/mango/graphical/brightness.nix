{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    gnomeExtensions.brightness-control-using-ddcutil
    ddcutil
  ];
  # https://github.com/NixOS/nixpkgs/blob/72f492e275fc29d44b3a4daf952fbeffc4aed5b8/nixos/modules/services/x11/desktop-managers/plasma5.nix#L257
  boot.kernelModules = [ "i2c-dev" ]; # for ddc
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", TAG+="uaccess"
  '';
}