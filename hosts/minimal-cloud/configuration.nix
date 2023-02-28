{ flake, inputs, modulesPath, ... }: {
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"

    flake.nixosModules.base
    flake.nixosModules.cloud-vps-initial
    inputs.disko.nixosModules.disko
  ];
  networking.hostName = "minimal-cloud";

  nixpkgs.hostPlatform = "x86_64-linux";
  # nixpkgs.hostPlatform = "aarch64-linux";

  # disko.devices.disk.disk1.device = "/dev/sda";
  # disko.devices.disk.disk1.device = "/dev/vda";
}