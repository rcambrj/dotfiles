{ flake, inputs, ... }: {
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.standard-disk
    flake.nixosModules.common
    flake.nixosModules.cloud-vps
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  networking.hostName = "orange";

  disko.devices.disk.disk1.device = "/dev/sda";
}