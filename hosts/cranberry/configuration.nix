#
# this machine is used for running the home's entertainment
# * jellyfin
# * radarr
# * sonarr
# * transmission
# * nzbget
# * vpn
#
{ flake, inputs, modulesPath, ... }: let
  group = import ./group.nix;
in {
  imports = [
    # TODO: https://github.com/numtide/nixos-facter/issues/125
    # inputs.nixos-facter-modules.nixosModules.facter
    # { config.facter.reportPath = ./facter.json; }
    "${toString modulesPath}/profiles/all-hardware.nix"

    inputs.nix-pia-vpn.nixosModules.default
    inputs.agenix-template.nixosModules.default
    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.common
    flake.nixosModules.bare-metal-usb
    flake.nixosModules.config-intel
    ./vpn
    ./http
    ./auth

    ./downloads-enabled.nix
    ./backup.nix
    ./jackett.nix
    ./jellyfin.nix
    ./nzbget.nix
    ./radarr.nix
    ./sonarr.nix
    ./transmission.nix
    ./statistics.nix
  ];

  networking.hostName = "cranberry";
  age.secrets = {
    acme-cloudflare.file = ../../secrets/acme-cloudflare.age;
    pia-vpn.file = ../../secrets/pia-vpn.age;
    backup-bucket = {
      file = ../../secrets/cranberry-backup-bucket.age;
    };
    backup-credentials = {
      file = ../../secrets/cranberry-backup-credentials.age;
    };
    backup-encryption-key = {
      file = ../../secrets/cranberry-backup-encryption-key.age;
    };
    cranberry-oauth2-proxy-client-secret = {
      file = ../../secrets/cranberry-oauth2-proxy-client-secret.age;
    };
    cranberry-oauth2-proxy-cookie-secret = {
      file = ../../secrets/cranberry-oauth2-proxy-cookie-secret.age;
    };
  };

  fileSystems = {
    "/var/lib" = {
      device = "/dev/disk/by-label/NIXOSSTATE";
      fsType = "ext4";
      neededForBoot = true;
    };
  };

  # this group should be able to manipulate media files
  users.groups.media = {};

  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "powersave";
        energy_performance_preference = "power";
        turbo = "never";
        # Intel(R) Celeron(R) N5105 @ 2.00GHz
        # https://askubuntu.com/a/1064309/1682130
      };
    };
  };

  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network = {
    # TOPTON 4-port bridge
    netdevs."10-br0".netdevConfig = {
      Kind = "bridge";
      Name = "br0";
      MACAddress = "a6:99:b0:72:64:7e";
    };
    networks."11-enp1s0" = {
      matchConfig.Name = "enp1s0";
      networkConfig.Bridge = "br0";
    };
    networks."11-enp2s0" = {
      matchConfig.Name = "enp2s0";
      networkConfig.Bridge = "br0";
    };
    networks."11-enp3s0" = {
      matchConfig.Name = "enp3s0";
      networkConfig.Bridge = "br0";
    };
    networks."11-enp4s0" = {
      matchConfig.Name = "enp4s0";
      networkConfig.Bridge = "br0";
    };
    networks."12-br0" = {
      matchConfig.Name = "br0";
      networkConfig.DHCP = "ipv4";
      networkConfig.LinkLocalAddressing = "no";
      dhcpV4Config.UseHostname = "no";
      linkConfig.RequiredForOnline = "yes";
      routingPolicyRules = [{
        # this helps to prevent VPN rules/routes affecting SSH while debugging
        Priority = 100;
        To = "192.168.142.0/24";
      }];
      # bypass local nameserver setting so that DNS requests will go through VPN
      dhcpV4Config.UseDNS = "no";
    };
    # 60 is pia-vpn related
  };
  services.resolved = {
    enable = true;
    extraConfig = ''
    [Resolve]
    DNS=192.168.142.1
    Domains=~cambridge.me
    '';
  };

  systemd.tmpfiles.settings = {
    "10-media" = {
      "/var/lib/media" = {
        d = {
          user = "root";
          group = group;
          mode = "0750";
        };
      };
      "/var/lib/media/tvshows" = {
        d = {
          user = "root";
          group = group;
          mode = "0770";
        };
      };
      "/var/lib/media/movies" = {
        d = {
          user = "root";
          group = group;
          mode = "0770";
        };
      };
      "/var/lib/media/downloads" = {
        d = {
          user = "root";
          group = group;
          mode = "0750";
        };
      };
      "/var/lib/media/downloads/nzbget" = {
        d = {
          user = "root";
          group = group;
          mode = "0770";
        };
      };
      "/var/lib/media/downloads/transmission" = {
        d = {
          user = "root";
          group = group;
          mode = "0770";
        };
      };
    };
  };
}
