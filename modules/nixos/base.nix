{ config, lib, pkgs, ... }:
with lib;
{
  system.stateVersion = "23.11";
  nix.channel.enable = false;

  nix.settings.substituters = config.nix.settings.trusted-substituters;
  nix.settings.trusted-substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
    "https://cache.garnix.io"
    "https://numtide.cachix.org"

  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE"
  ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
    accept-flake-config = true
    narinfo-cache-negative-ttl = 60
  '';

  time.timeZone = "Europe/Amsterdam";
  services.journald.extraConfig = ''
    Storage=volatile
  '';
  systemd.extraConfig = "DefaultLimitNOFILE=4096";
  networking.firewall.enable = true;
  nixpkgs.config.allowUnfree = true;
}