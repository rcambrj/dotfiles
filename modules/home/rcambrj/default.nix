{ config, inputs, perSystem, pkgs, ... }:
let
  me = import ./me.nix;
in {
  imports = [
    ./ssh.nix
    ./shell.nix
    ./git.nix
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "23.11";
  home.username = me.user;
  home.homeDirectory = pkgs.lib.mkForce (if pkgs.stdenv.isDarwin then "/Users/${me.user}" else "/home/${me.user}");

  home.packages = with pkgs; [
    asciinema
    binwalk
    coreutils
    curl
    dtc # device-tree-compiler
    gnupg
    gnumake
    gnutar zstd
    htop
    iftop
    nodePackages.localtunnel
    ncdu
    nix-output-monitor
    openocd
    openssh
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
    fira-code-nerdfont # FiraCodeNFM-Reg
    # TODO: which pkgs contains HackNFM-Regular ?
  ];

  fonts.fontconfig.enable = true;

  programs.awscli = {
    enable = true;
    settings = {
      "default" = {
        region = "eu-central-1";
        output = "json";
      };
    };
  };

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
