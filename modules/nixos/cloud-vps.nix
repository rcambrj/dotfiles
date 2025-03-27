{ inputs, ... }: _: {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  age.identityPaths = [ "/root/.ssh/id_ed25519" ];
}