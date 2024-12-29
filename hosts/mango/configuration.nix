# ThinkPad T14S workstation laptop
{ flake, inputs, perSystem, ... }: {
  imports = [
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

}
