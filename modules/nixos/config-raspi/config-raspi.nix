{ config, flake, inputs, lib, modulesPath, pkgs, ... }: with lib; {
  imports = [
    "${toString modulesPath}/profiles/base.nix"
    inputs.nix-pi-loader.nixosModules.default
    ./nixos-hardware/pi3.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  boot.pi-loader = {
    enable = true;
  };
  boot.loader.generic-extlinux-compatible-pi-loader.useGenerationDeviceTree = false;

  # nixos-hardware.raspberry-pi-3 configures UARTs as consoles
  # raspi UARTs are scarce. don't be greedy at this level.
  # TODO: figure out how to *remove* things from config
  # in the meantime, see `pi3.nix`
  # https://raspberrypi.stackexchange.com/questions/45570
  # https://www.raspberrypi.com/documentation/computers/configuration.html#mini-uart-and-cpu-core-frequency
  # boot.kernelParams = ?;

  system.build.image = (import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    format = "raw";
    partitionTableType = "efi";
    copyChannel = false;
    diskSize = "auto";
    additionalSpace = "64M";
    bootSize = "1G";
    touchEFIVars = false;
    installBootLoader = true;
  });

  zramSwap = {
    enable = true;
  };
}
