{ inputs, ... }: { config, lib, modulesPath, pkgs, ... }: with lib; let
  sshKeyLocation = "/mnt/conf/id_ed25519"; # ensure that this is persisted across boots
  repositoryLocation = "git+ssh://git@github.com/rcambrj/dotfiles?ref=main";
  defaultFlakePath = config.networking.hostName;

  updateScript = pkgs.writeShellScriptBin "update" ''
    #!/usr/bin/env bash
    #
    # Gets latest from github repository
    # Then performs nixos-rebuild switch
    #

    set -e

    # if REPO_DIR doesn't exist, will create
    REPO_DIR="/flake"
    # ensure this is persisted across boots
    SSH_KEY="${sshKeyLocation}"
    REPOSITORY="${repositoryLocation}"
    # path within the flake
    MACHINE="''${1:-${defaultFlakePath}}"

    if [ "$EUID" -ne 0 ]; then
      echo "Please run as root"
      exit 1
    fi

    if [ ! -f "$SSH_KEY" ]; then
      echo "Cannot locate SSH key"
      exit 1
    fi

    mkdir -p ~/.ssh
    cp $SSH_KEY ~/.ssh/id_ed25519
    chmod 700 ~/.ssh/id_ed25519

    if [ ! -d "$REPO_DIR" ]; then
      git clone $REPOSITORY $REPO_DIR
      cloned=true
    fi

    cd $REPO_DIR

    if [ "$cloned" != "true" ]; then
      git pull --rebase
    fi

    nixos-rebuild switch --flake ".#$MACHINE"
  '';
in {
  imports = [
    inputs.agenix.nixosModules.default
    "${toString modulesPath}/profiles/base.nix"
  ];

  # minimal profile is too minimal, use base.nix and steal these tricks
  xdg.autostart.enable = mkDefault false;
  xdg.icons.enable = mkDefault false;
  xdg.mime.enable = mkDefault false;
  xdg.sounds.enable = mkDefault false;

  services.openssh.hostKeys = [{
    type = "ed25519";
    path = "/mnt/conf/id_ed25519";
  }];
  age.identityPaths = [ "/mnt/conf/id_ed25519" ];

  programs.ssh.knownHostsFiles = [
    ./github_known_hosts # required for updateScript
  ];
  environment.systemPackages = [
    updateScript
  ];
  boot.initrd.availableKernelModules = [
    "mmc_block" "sdhci_acpi"
  ];
}