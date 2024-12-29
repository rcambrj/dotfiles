# ThinkPad T14S workstation laptop
{ flake, inputs, perSystem, ... }: {
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s
    flake.nixosModules.base
    flake.nixosModules.common
    flake.nixosModules.access-server # TODO: remove this
    flake.nixosModules.access-workstation
    flake.nixosModules.standard-disk
    ./graphical.nix
    ./home.nix
  ];

  networking.hostName = "mango";
  nixpkgs.hostPlatform = "x86_64-linux";

  disko.devices.disk.disk1.device = "/dev/nvme0n1";

  networking.networkmanager.enable = true;
}
