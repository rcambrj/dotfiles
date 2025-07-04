{ config, lib, pkgs, ... }:
with lib;
{
  environment.systemPackages = with pkgs; [
    # some basic utilities
    curl
    dig
    git
    htop btop
    iftop
    iotop
    ncdu
    ripgrep
    tmate
    tmux
    tree
    unrar
    unzip
    sysstat
    sysz
    usbtop
    usbutils
    vim
    wget
  ];

  programs.direnv.enable = true;
}