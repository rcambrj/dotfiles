{ flake, inputs, ... }: {
  imports = [
    # inputs.nixos-hardware.nixosModules.raspberry-pi-3
    # but without UART console:
    ./hardware-raspberry-pi-3.nix

    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.bare-metal-usb
    flake.nixosModules.config-raspi
    flake.lib.template
    ./http
    ./klipper.nix
  ];

  networking.hostName = "gooseberry";
  age.secrets = {
    acme-cloudflare.file = ../../secrets/acme-cloudflare.age;
    ldap-admin-ro-password.file = ../../secrets/ldap-admin-ro-password.age;
  };
  boot.pi-loader = {
    bootMode = "direct";
    configTxt = {
      all = {
        gpu_mem = 16;
      };
      pi3 = {
        dtoverlay = [
          # need the full UART on GPIO 14+15 for the BTT SKR
          # https://www.raspberrypi.com/documentation/computers/configuration.html#uarts-and-device-tree
          # https://raspberrypi.stackexchange.com/questions/45570/-/45571#45571
          # https://github.com/Ysurac/raspberry_kernel_mptcp/blob/master/arch/arm/boot/dts/overlays/pi3-disable-bt-overlay.dts
          # https://github.com/Ysurac/raspberry_kernel_mptcp/blob/master/arch/arm/boot/dts/overlays/pi3-miniuart-bt-overlay.dts
          # weird behaviour:
          # * "disable-bt" does not remove ttyS0
          # * "miniuart-bt" removes ttyS0
          # don't need bluetooth, so moving on.
          "disable-bt"
        ];
      };
    };
  };

  # https://github.com/NixOS/nixpkgs/issues/392278
  # services.auto-cpufreq = {
  #   enable = true;
  #   settings = {
  #     charger = {
  #       governor = "ondemand";
  #       energy_performance_preference = "performance";
  #       turbo = "auto";
  #     };
  #   };
  # };

  fileSystems = {
    "/var/lib" = {
      device = "/dev/disk/by-label/NIXOSSTATE";
      fsType = "ext4";
      neededForBoot = true;
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
}