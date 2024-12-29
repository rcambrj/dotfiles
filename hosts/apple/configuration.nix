{ config, inputs, flake, modulesPath, ... }: {
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.standard-disk
    flake.nixosModules.root-keys
    flake.nixosModules.cloud-vps
    inputs.disko.nixosModules.disko
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "apple";

  disko.devices.disk.disk1.device = "/dev/sda";
}