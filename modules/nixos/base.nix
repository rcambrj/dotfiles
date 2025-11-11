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
  networking.firewall.enable = true;
  nixpkgs.config.allowUnfree = true;

  # optimisations inspired by srvos
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
    xfs   = mkOverride 99 true;
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

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';

    # For more detail, see:
    #   https://0pointer.de/blog/projects/watchdog.html
    # settings.Manager = {
    #   # systemd will send a signal to the hardware watchdog at half
    #   # the interval defined here, so every 7.5s.
    #   # If the hardware watchdog does not get a signal for 15s,
    #   # it will forcefully reboot the system.
    #   RuntimeWatchdogSec = lib.mkDefault "15s";
    #   # Forcefully reboot if the final stage of the reboot
    #   # hangs without progress for more than 30s.
    #   # For more info, see:
    #   #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
    #   RebootWatchdogSec = lib.mkDefault "30s";
    #   # Forcefully reboot when a host hangs after kexec.
    #   # This may be the case when the firmware does not support kexec.
    #   KExecWatchdogSec = lib.mkDefault "1m";
    #
    #   # increase open file limit
    #   LimitNOFILE = 4096;
    # };
  };

  # Make sure the serial console is visible in qemu when testing the server configuration
  # with nixos-rebuild build-vm
  virtualisation.vmVariant.virtualisation.graphics = mkDefault false;
}