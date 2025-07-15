{ config, lib, modulesPath, pkgs, ... }: {
  imports = [
    ./grow-partition.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.build.image = (import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    format = "raw";
    partitionTableType = "efi";
    copyChannel = false;
    diskSize = "auto";
    additionalSpace = "64M";
    bootSize = "256M";
  });

  boot.loader = {
    timeout = 1;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
  boot.initrd.availableKernelModules = [ "uas" ];
  boot.kernelParams = [
    "console=tty0"
    "boot.shell_on_fail"
    "root=LABEL=nixos" # see iso-image.nix for why this is useful
  ];

  boot.growPartitionCustom.enable = true;
  fileSystems = {
    # use mkDefault so that disko doesn't conflict during disko-install
    "/boot" = lib.mkDefault {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
    "/" = lib.mkDefault {
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };
    "/mnt/root" = lib.mkDefault {
      device = "/dev/root";
      neededForBoot = true;
      autoResize = true; # resizes filesystem to occupy whole partition
      fsType = "ext4";
    };
    "/nix" = lib.mkDefault {
      device = "/mnt/root/nix";
      neededForBoot = true;
      options = [ "defaults" "bind" ];
      depends = [ "/mnt/root" ];
    };
    "/mnt/conf" = lib.mkDefault {
      device = "/dev/disk/by-label/NIXOSCONF";
      neededForBoot = true;
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
  ];
}