# Raspberry Pi 3 and Z2W for now
{ inputs, ... }: { config, lib, modulesPath, pkgs, ... }: {

  imports = [
    inputs.nix-pi-loader.nixosModules.default
    ./grow-partition.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  system.build.image = (import inputs.nix-pi-loader.nixosModules.make-disk-image {
    inherit lib config pkgs;
    format = "raw";
    partitionTableType = "legacy+boot";
    copyChannel = false;
    diskSize = "auto";
    additionalSpace = "64M";
    bootSize = "128M";
    touchEFIVars = false;
    installBootLoader = true;
    label = "nixos";
  });
  boot.pi-loader = {
    enable = true;
  };
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };
  boot.growPartitionCustom = {
    enable = true;
    device = "/dev/disk/by-label/nixos";
  };
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };
    "/" = {
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };
    "/mnt/root" = {
      device = "/dev/disk/by-label/nixos";
      neededForBoot = true;
      autoResize = true; # resizes filesystem to occupy whole partition
      fsType = "ext4";
    };
    "/nix" = {
      device = "/mnt/root/nix";
      neededForBoot = true;
      options = [ "defaults" "bind" ];
      depends = [ "/mnt/root" ];
    };
    "/mnt/conf" = {
      device = "/dev/disk/by-label/NIXOSCONF";
      neededForBoot = true;
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };
  environment.systemPackages = with pkgs; [ libraspberrypi ];
}