# ThinkPad T14S workstation laptop
{ flake, inputs, lib, perSystem, pkgs, ... }: {
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
    flake.nixosModules.base
    flake.nixosModules.common
    flake.nixosModules.access-workstation
    flake.nixosModules.standard-disk
    ./graphical.nix
    ./home-manager.nix
    ./input.nix
  ];

  networking.hostName = "mango";
  nixpkgs.hostPlatform = "x86_64-linux";

  disko.devices.disk.disk1.device = "/dev/nvme0n1";

  systemd.network.enable = lib.mkForce false;
  networking.networkmanager.enable = true;

  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-elan;
    };
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "rcambrj" ];
  };

  services.thinkfan.enable = true;

  # required for any user to use zsh
  programs.zsh.enable = true;
}
