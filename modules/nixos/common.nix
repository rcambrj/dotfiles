{ config, lib, pkgs, ... }:
with lib;
{
  environment.systemPackages = with pkgs; [
    # some basic utilities
    curl
    dig
    git
    htop
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
    vim
    wget
  ];
}