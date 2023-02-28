{ config, flake, inputs, lib, modulesPath, options, perSystem, pkgs, ... }: {
  imports = [
    flake.nixosModules.common
    flake.nixosModules.bare-metal-usb
    flake.nixosModules.config-raspi
    inputs.vscode-server.nixosModules.default
  ];

  networking.hostName = "tacxble-dev";

  boot.pi-loader.configTxt = lib.recursiveUpdate options.boot.pi-loader.configTxt.default {
    all = {
      # ttyAMA0 (P011 UART) will be used for bluetooth
      # ttyS0 (miniUART) will be used for the tacx
      # there are no UARTs left on the raspi 3 / Z2W
      # so don't try to use one for a console
      # https://raspberrypi.stackexchange.com/questions/45570
      # https://www.raspberrypi.com/documentation/computers/configuration.html#mini-uart-and-cpu-core-frequency
      enable_uart = 1;
      core_freq = 250;
      gpu_mem = 16;
    };
  };
  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network = {
    networks."10-wired" = {
      matchConfig.Name = "e*";
      linkConfig.RequiredForOnline = "routable";
      networkConfig.DHCP = "yes";
    };
  };

  environment.systemPackages = with pkgs; [
    perSystem.tacxble.tacxble
    uucp # provides cu

    # deps for https://github.com/totalreverse/ttyT1941
    # python312
    # python312Packages.pip
  ];

  fileSystems = {
    "/home/nixos" = {
      device = "/dev/disk/by-label/NIXOSHOME";
      fsType = "ext4";
      neededForBoot = true;
    };
  };

  users.users.nixos.extraGroups = [
    "dialout" # permits /dev/tty*
  ];

  hardware.bluetooth.enable = true;
  services.vscode-server.enable = true;
  programs.nix-ld.enable = true;
  programs.direnv.enable = true;

  users.users.nixos.openssh.authorizedKeys.keys = [
    # https://github.com/srounce.keys
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/7pdu+Sp4yXRq5ZXMJFgQevioqyWi5jB72Eh3SYgsg"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFC5ITONR30t23/Qg/bytI8uKA/EOBEzCZ8Ks9YNfv6P"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOAA2X72Mnp8+zI3GuZk6as/voiudMuQXwwYqbJUKELb"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB9+VAEUHdEfcoJHcr5jlqx0BBAuoH5hLAJh0FPdhLFU"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVX2VCktSzfbIhFqWUDSN/s09rSKIQlxrWPL6uuYhEZ"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICU9Z2v82Gv397EWoAlYc7BOeqGQzj4ENtNd7SqW8fcg"
  ];
}