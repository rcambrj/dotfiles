{ config, lib, pkgs, ... }:
with lib;
{
  imports = [
    ./base.nix
  ];

  environment.systemPackages = with pkgs; [
    # some basic utilities
    curl
    dig
    git
    htop
    iftop
    ncdu
    ripgrep
    tmate
    tmux
    tree
    unrar
    unzip
    sysz
    vim
    wget
  ];
}