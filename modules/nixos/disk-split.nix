{ config, inputs, lib, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  disko.devices = {
    disk.disk1 = {
      # IMPORTANT: set this before nixos-anywhere!
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              # mountpoint = "/boot";
            };
          };
          const = {
            name = "NIXOSCONF";
            size = "1M";
            content = {
              type = "filesystem";
              format = "vfat";
              # mountpoint = "/mnt/conf";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "pool";
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "64G";
            name = "NIXOS";
            content = {
              type = "filesystem";
              format = "ext4";
              # mountpoint = "/mnt/root";
              # mountOptions = [
              #   "defaults"
              # ];
            };
          };
          state = {
            size = "100%FREE";
            name = "NIXOSSTATE";
            content = {
              type = "filesystem";
              format = "ext4";
              # mountpoint = "/var/lib";
              # mountOptions = [
              #   "defaults"
              # ];
            };
          };
        };
      };
    };
  };
}