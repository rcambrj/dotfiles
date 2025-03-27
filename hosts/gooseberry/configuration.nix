{ flake, inputs, modulesPath, ... }: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.bare-metal-usb
    flake.nixosModules.config-raspi
    flake.lib.template
  ];

  networking.hostName = "gooseberry";
  age.secrets = {
    # acme-cloudflare.file = ../../secrets/acme-cloudflare.age;
  };
  boot.pi-loader = {
    bootMode = "direct";
  };
}