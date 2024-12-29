{ flake, inputs, perSystem, ... }: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager.users.rcambrj.imports = [
    flake.homeModules.rcambrj
    { home.stateVersion = "23.11"; }
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs perSystem; };
}