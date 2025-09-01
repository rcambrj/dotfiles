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
    nettools # arp
    ncdu
    ripgrep
    tmate
    tmux
    tree
    unrar
    unzip
    sysstat
    sysz
    tcpdump
    usbtop
    usbutils
    vim
    wget
  ];

  programs.direnv.enable = true;
}