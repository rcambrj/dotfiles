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

  # inspired by srvos
  # https://github.com/nix-community/srvos/blob/1e475337ce3eeb01b400291cef4c187ae76649c0/nixos/server/default.nix
  # https://github.com/nix-community/srvos/blob/1e475337ce3eeb01b400291cef4c187ae76649c0/nixos/common/default.nix
  xdg.autostart.enable = mkDefault false;
  xdg.icons.enable = mkDefault false;
  xdg.menus.enable = mkDefault false;
  xdg.mime.enable = mkDefault false;
  xdg.sounds.enable = mkDefault false;
  fonts.fontconfig.enable = mkDefault false;
  documentation.man.enable = mkDefault false;
  documentation.nixos.enable = mkDefault false;
  environment.stub-ld.enable = mkDefault false;
  programs.command-not-found.enable = mkDefault false;
  environment.ldso32 = mkDefault null;
  boot.tmp.cleanOnBoot = mkDefault true;
  boot.supportedFilesystems = {
    # profiles/base.nix sets some of these so don't use mkDefault
    auto  = mkOverride 99 false;
    btrfs = mkOverride 99 false;
    cifs  = mkOverride 99 false;
    ext4  = mkOverride 99 true;
    f2fs  = mkOverride 99 false;
    ntfs  = mkOverride 99 false;
    tmpfs = mkOverride 99 true;
    vfat  = mkOverride 99 true;
    xfs   = mkOverride 99 false;
    zfs   = mkOverride 99 false;
  };

  boot.loader.grub.configurationLimit = mkDefault 5;
  boot.loader.systemd-boot.configurationLimit = mkDefault 5;

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.network.wait-online.enable = false;

  systemd = {
    # Given that our systems are headless, emergency mode is useless.
    # We prefer the system to attempt to continue booting so
    # that we can hopefully still access it remotely.
    enableEmergencyMode = false;

    # For more detail, see:
    #   https://0pointer.de/blog/projects/watchdog.html
    watchdog = {
      # systemd will send a signal to the hardware watchdog at half
      # the interval defined here, so every 7.5s.
      # If the hardware watchdog does not get a signal for 15s,
      # it will forcefully reboot the system.
      runtimeTime = mkDefault "15s";
      # Forcefully reboot if the final stage of the reboot
      # hangs without progress for more than 30s.
      # For more info, see:
      #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
      rebootTime = mkDefault "30s";
      # Forcefully reboot when a host hangs after kexec.
      # This may be the case when the firmware does not support kexec.
      kexecTime = mkDefault "1m";
    };

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  # Make sure the serial console is visible in qemu when testing the server configuration
  # with nixos-rebuild build-vm
  virtualisation.vmVariant.virtualisation.graphics = mkDefault false;

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