{ flake, inputs, ... }: {
  imports = [
    ./cloud-vps-initial.nix
    inputs.agenix.nixosModules.default
  ];

  age.identityPaths = [ "/root/.ssh/id_ed25519" ];
}