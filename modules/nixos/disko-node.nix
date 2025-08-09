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

  # if mountpoint is declared for any partition, its counterpart entry in `fileSystems` will be changed
  # don't declare any mountpoints and use disko only for partitioning (don't use disko-install)
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
              extraArgs = ["-n" "ESP"];
            };
          };
          nixosconf = {
            name = "NIXOSCONF";
            size = "1M";
            content = {
              type = "filesystem";
              format = "vfat";
              # mountpoint = "/mnt/conf";
              extraArgs = ["-n" "NIXOSCONF"];
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
            size = "32G";
            name = "nixos";
            content = {
              type = "filesystem";
              format = "ext4";
              # mountpoint = "/mnt/root";
              extraArgs = ["-L" "nixos"];
            };
          };
          nixosstate = {
            size = "32G";
            name = "NIXOSSTATE";
            content = {
              type = "filesystem";
              format = "ext4";
              # mountpoint = "/var/lib";
              extraArgs = ["-L" "NIXOSSTATE"];
            };
          };
          data = {
            size = "100%FREE";
            name = "DATA";
            content = {
              type = "filesystem";
              format = "ext4";
              # mountpoint = "/data";
              extraArgs = ["-L" "DATA"];
            };
          };
        };
      };
    };
  };
}