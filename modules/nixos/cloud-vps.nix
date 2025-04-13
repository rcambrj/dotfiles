{ inputs, ... }: _: {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  age.identityPaths = [ "/root/.ssh/id_ed25519" ];

  boot.loader.grub.configurationLimit = lib.mkDefault 1;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 1;
}