{ flake, modulesPath, ... }: {
  imports = [
    "${toString modulesPath}/profiles/all-hardware.nix"
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.standard-disk
    flake.nixosModules.root-keys
    flake.nixosModules.cloud-vps
    ./netbird.nix
    ./statistics.nix
  ];

  networking.hostName = "coconut";
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.useNetworkd = true;

  disko.devices.disk.disk1.device = "/dev/vda";

  services.resolved.enable = true;
}
