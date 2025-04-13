{ flake, inputs, modulesPath, pkgs, ... }: {
  imports = [
    "${toString modulesPath}/profiles/all-hardware.nix"

    inputs.agenix-template.nixosModules.default
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.bare-metal-usb
    flake.nixosModules.config-intel
    ./http
    ./fluidd.nix
    ./klipper.nix
    ./mobileraker.nix
    ./moonraker.nix
    ./ustreamer.nix
  ];

  networking.hostName = "elderberry";
  age.secrets = {
    acme-cloudflare.file = ../../secrets/acme-cloudflare.age;
    ldap-admin-ro-password.file = ../../secrets/ldap-admin-ro-password.age;
  };

  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };

  boot.extraModprobeConfig = ''
    # fix Dell Wyse 3040 hanging on reboot
    # https://github.com/up-board/up-community/wiki/Ubuntu_20.04#hang-on-shutdown-or-reboot-for-up-board
    # https://www.reddit.com/r/Atomic_Pi/wiki/ubuntu/
    blacklist dw_dmac
    blacklist dw_dmac_core
    install dw_dmac /bin/true
    install dw_dmac_core /bin/true
  '';

  systemd.tmpfiles.settings = {
    "10-var-conf"."/var/conf".d = {
      # this is important during image creation.
      user = "root";
      group = "root";
      mode = "0700";
    };
  };

  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network = {
    networks = {
      "10-wired" = {
        matchConfig.Name = "e*";
        networkConfig = {
          DHCP = "yes";
        };
      };
      "20-canbus" = {
        # https://www.reddit.com/r/klippers/comments/zf3rcx
        matchConfig.Name = "can*";
        canConfig = {
          BitRate = 1000000;
        };
      };
    };
  };

  systemd.services.can-net-txqueuelen = {
    serviceConfig = {
      Type = "oneshot";
    };
    wantedBy = [ "sys-subsystem-net-devices-can0.device" ];
    script = ''
      ${pkgs.nettools}/bin/ifconfig can0 txqueuelen 1024
    '';
  };

  boot.consoleLogLevel = pkgs.lib.mkDefault 7;
}