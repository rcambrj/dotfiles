{ config, flake, lib, inputs, pkgs, ... }: with lib; let
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
    SSH_KEY="/mnt/conf/id_ed25519"
    REPOSITORY="ssh://git@github.com/rcambrj/dotfiles"
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

  # the second and further time this is run, the HEAD of main is not fetched :(
  # TODO: determine how to nixos-rebuild switch --flake github:... with the latest every time
  updateScriptDev = pkgs.writeShellScriptBin "updateDev" ''
    #!/usr/bin/env bash
    #
    # Performs nixos-rebuild switch against the host's configuration
    #

    set -e
    SSH_KEY="${sshKeyLocation}"
    REPOSITORY="${repositoryLocation}"
    MACHINE="''${1:-${defaultFlakePath}}"

    if [ "$EUID" -ne 0 ]; then
      echo "Please run as root"
      exit 1
    fi

    if [ ! -f "$SSH_KEY" ]; then
      echo "Cannot locate SSH key"
      exit 1
    fi

    NIX_SSHOPTS="-i $SSH_KEY" nixos-rebuild switch --flake "$REPOSITORY#$MACHINE"
  '';
in {
  imports = [
    inputs.agenix.nixosModules.default
  ];


  # minimal profile is too minimal, but steal these tricks
  environment.noXlibs = mkDefault false;
  xdg.autostart.enable = mkDefault false;
  xdg.icons.enable = mkDefault false;
  xdg.mime.enable = mkDefault false;
  xdg.sounds.enable = mkDefault false;

  boot.kernelParams = [
    "console=tty0"
    "boot.shell_on_fail"
    "root=LABEL=nixos" # see iso-image.nix for why this is useful
  ];
  boot.loader.timeout = mkForce 1;
  boot.initrd.availableKernelModules = [ "uas" ];

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
    "/" = {
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };
    "/mnt/root" = {
      device = "/dev/root";
      neededForBoot = true;
      autoResize = true; # resizes filesystem to occupy whole partition
      fsType = "ext4";
    };
    "/nix" = {
      device = "/mnt/root/nix";
      neededForBoot = true;
      options = [ "defaults" "bind" ];
      depends = [ "/mnt/root" ];
    };
    "/mnt/conf" = {
      device = "/dev/disk/by-label/NIXOSCONF";
      neededForBoot = true;
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  # resizes partition to occupy empty space
  # growPartition=true will grow the tmpfs at / (we don't need that)
  # ideally growPartition would allow the root device to be customised,
  # but it doesn't, so below is copy+paste with custom rootDevice value
  # from https://github.com/NixOS/nixpkgs/blob/6afb255d976f85f3359e4929abd6f5149c323a02/nixos/modules/system/boot/grow-partition.nix
  systemd.services.growpart-custom = {
    wantedBy = [ "-.mount" ];
    after = [ "-.mount" ];
    before = [ "systemd-growfs-root.service" "shutdown.target" ];
    conflicts = [ "shutdown.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutSec = "infinity";
      SuccessExitStatus = "0 1";
    };

    script = ''
      rootDevice="/dev/root"
      rootDevice="$(readlink -f "$rootDevice")"
      parentDevice="$rootDevice"
      while [ "''${parentDevice%[0-9]}" != "''${parentDevice}" ]; do
        parentDevice="''${parentDevice%[0-9]}";
      done
      partNum="''${rootDevice#''${parentDevice}}"
      if [ "''${parentDevice%[0-9]p}" != "''${parentDevice}" ] && [ -b "''${parentDevice%p}" ]; then
        parentDevice="''${parentDevice%p}"
      fi
      "${pkgs.cloud-utils.guest}/bin/growpart" "$parentDevice" "$partNum"
      "${pkgs.e2fsprogs}/bin/resize2fs" $rootDevice
    '';
  };

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
    updateScriptDev
  ];
}