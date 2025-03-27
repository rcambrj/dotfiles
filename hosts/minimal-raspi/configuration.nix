#
# this machine is used for:
# * booting on (suitable) hardware + debugging + recovery
# * a minimal build to be converted to another machine
# * a makeshift nix builder
#
{ flake, inputs, modulesPath, ... }: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.bare-metal-usb
    flake.nixosModules.config-raspi
  ];

  networking.hostName = "minimal-raspi";

  boot.binfmt.emulatedSystems = [ "armv6l-linux" "armv7l-linux" "x86_64-linux" ];

  # since this machine config will be plugged into machines which potentially
  # have static routes and NS configurations already, enable avahi so that the
  # hostname can be broadcast via zeroconf name resolution.
  services.avahi = {
    enable = true;
    hostName = "minimal-raspi-nomad"; # minimal-raspi-nomad.local
    nssmdns4 = true;
    wideArea = false;
    publish = {
      enable = true;
      workstation = true;
      addresses = true;
    };
  };
}