{ flake, inputs, modulesPath, ... }: {
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"

    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.standard-disk
    flake.nixosModules.common
    flake.nixosModules.cloud-vps
    ./photoprism-backup
  ];

  networking.hostName = "orange";


  nixpkgs.hostPlatform = "aarch64-linux";

  disko.devices.disk.disk1.device = "/dev/sda";

  age.secrets = {
    photoprism-sftp-password = {
      file = ../../secrets/photoprism-sftp-password.age;
    };
    photoprism-backup-bucket = {
      file = ../../secrets/photoprism-backup-bucket.age;
    };
    photoprism-backup-credentials = {
      file = ../../secrets/photoprism-backup-credentials.age;
    };
    photoprism-backup-encryption-key = {
      file = ../../secrets/photoprism-backup-encryption-key.age;
    };
  };

}