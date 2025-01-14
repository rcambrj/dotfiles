{ flake, inputs, modulesPath, ... }: {
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"

    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.standard-disk
    flake.nixosModules.common
    flake.nixosModules.cloud-vps
  ];

  networking.hostName = "orange";


  nixpkgs.hostPlatform = "aarch64-linux";

  disko.devices.disk.disk1.device = "/dev/sda";
}