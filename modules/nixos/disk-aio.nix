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
              mountpoint = "/boot";
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
            size = "64G";
            name = "nixos";
            content = {
              type = "filesystem";
              format = "ext4";
              # mount at / even if that will change on normal boot
              # so that /nix/store points to the right place
              mountpoint = "/mnt/root";
              extraArgs = ["-L" "nixos"];
            };
          };
          nixosstate = {
            size = "100%FREE";
            name = "NIXOSSTATE";
            content = {
              type = "filesystem";
              format = "ext4";
              extraArgs = ["-L" "NIXOSSTATE"];
            };
          };
        };
      };
    };
    nodev = {
      realroot = {
        type = "nodev";
        mountpoint = "/";
        fsType = "tmpfs";
        device = "tmpfs";
        mountOptions = [ "mode=0755" ];
      };
      store = {
        type = "nodev";
        mountpoint = "/nix";
        fsType = "auto";
        device = "/mnt/root/nix";
        mountOptions = [ "defaults" "bind" ];
        # depends = [ "/mnt/root" ]; # not supported by disko. do this discretely
      };
    };
  };

  fileSystems."/nix".depends = [ "/mnt/root" ];
}