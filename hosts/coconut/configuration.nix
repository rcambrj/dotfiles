{ flake, modulesPath, ... }: {
  imports = [
    "${toString modulesPath}/profiles/all-hardware.nix"
    flake.nixosModules.common
    flake.nixosModules.cloud-vps
    ./photoprism-backup
    ./netbird.nix
    ./statistics.nix
  ];

  networking.hostName = "coconut";
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.useNetworkd = true;

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

  disko.devices.disk.disk1.device = "/dev/vda";

  services.resolved = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 8081 ];
  services.openssh.settings.GatewayPorts = "yes";
}
