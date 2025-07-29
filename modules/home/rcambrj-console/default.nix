# this would be best split into separately-importable modules
{ config, inputs, lib, perSystem, pkgs, ... }:
let
  me = import ./me.nix;
in {
  imports = [
    ./ssh.nix
    ./shell.nix
    ./git.nix
  ];

  programs.home-manager.enable = lib.mkDefault true;
  home.username = lib.mkDefault me.user;
  # override with 75 so that mkForce can still be used to change the value
  home.homeDirectory = pkgs.lib.mkOverride 75 (if pkgs.stdenv.isDarwin then "/Users/${me.user}" else "/home/${me.user}");

  home.packages = with pkgs; [
    asciinema
    # balena-cli # doesn't build on darwin
    binwalk
    certstrap
    coreutils
    curl
    dtc # device-tree-compiler
    gnupg
    gnumake
    gnutar zstd
    htop btop
    iftop
    kubectl kubernetes-helm k9s
    nodePackages.localtunnel
    ncdu
    nix-output-monitor
    openocd
    openssh
    pciutils
    qemu
    ripgrep
    sysz
    tig
    tmate
    tmux
    tree
    unrar
    unzip
    watch
    wget

    # fonts
    # for iTerm2
    nerd-fonts.fira-code # FiraCodeNFM-Reg
    # TODO: which pkgs contains HackNFM-Regular ?
  ] ++
  (if pkgs.stdenv.isLinux then [
     lm_sensors
  ] else []);

  fonts.fontconfig.enable = true;

  # temporarily disable awscli until this makes it to nixos-unstable
  # https://github.com/NixOS/nixpkgs/issues/367876
  # programs.awscli = {
  #   enable = true;
  #   settings = {
  #     "default" = {
  #       region = "eu-central-1";
  #       output = "json";
  #     };
  #   };
  # };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.granted = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}
