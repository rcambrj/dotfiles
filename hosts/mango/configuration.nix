# ThinkPad T14S workstation laptop
{ flake, inputs, perSystem, ... }: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    flake.nixosModules.base
    flake.nixosModules.common
    flake.nixosModules.access-server # TODO: remove this
    flake.nixosModules.access-workstation
    flake.nixosModules.standard-disk
    ./graphical.nix
  ];

  networking.hostName = "mango";
  nixpkgs.hostPlatform = "x86_64-linux";

  home-manager.users.rcambrj.imports = [
    flake.homeModules.rcambrj
    { home.stateVersion = "23.11"; }
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs perSystem; };
}
