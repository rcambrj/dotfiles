{ inputs, lib, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-template.nixosModules.default
  ];

  age.identityPaths = [ "/root/.ssh/id_ed25519" ];

  boot.loader.grub.configurationLimit = 1;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 1;
}