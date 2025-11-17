{ config, flake, inputs, lib, modulesPath, pkgs, perSystem, ... }: {
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"

    inputs.agenix.nixosModules.default
    inputs.agenix-template.nixosModules.default

    flake.nixosModules.access-server
    flake.nixosModules.disko-standard
  ];

  nixpkgs.config.allowUnfree = true;
  age.identityPaths = [ "/root/.ssh/id_ed25519" ];
  networking.hostName = "lemon";
  nixpkgs.hostPlatform = "aarch64-linux";
  disko.devices.disk.disk1.device = "/dev/sda";

  services.netbird.package = let
    broken = true;
  in
    lib.mkForce (if broken then pkgs.netbird else perSystem.nixpkgs-netbird.netbird);

  age.secrets.netbird-private-key.file = ./. + "/../../secrets/${config.networking.hostName}-netbird-privatekey.age";
  age-template.files.netbird-secrets = {
    path = "/etc/${config.services.netbird.clients.default.dir.baseName}/config.d/60-secrets.json";
    vars = {
      privatekey = config.age.secrets.netbird-private-key.path;
    };
    content = ''
      {
        "PrivateKey": "$privatekey"
      }
    '';
  };
  services.netbird.clients.default = {
    port = 51820;
    openFirewall = true;
    hardened = false;
  };
}