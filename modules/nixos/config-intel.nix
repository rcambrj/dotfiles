{ pkgs, modulesPath, lib, config, ... }: {
  imports = [
    "${toString modulesPath}/profiles/base.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.build.image = (import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    format = "raw";
    partitionTableType = "efi";
    copyChannel = false;
    diskSize = "auto";
    additionalSpace = "64M";
    bootSize = "1G";
  });

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}