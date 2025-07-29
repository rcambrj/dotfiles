# https://linbit.com/drbd-user-guide/drbd-guide-9_0-en/
# https://manpages.debian.org/testing/drbd-utils/drbd.conf-9.0.5.en.html
#
# first disk setup:
# https://linbit.com/drbd-user-guide/drbd-guide-9_0-en/#s-first-time-up
# if needed, wipe existing filesystem (ctrl+c after some seconds)
# dd if=/dev/zero of=/dev/pool/DATA
#
{ config, lib, pkgs, ... }: with lib; let
  port = 7788;
  resource = "r0";
  backDevice = "/dev/pool/DATA";
  nodes = {

    "0" = {
      name = "cranberry";
      ip = "192.168.142.20";
      # dd: 480MB/s dropping to 170MB/s after heat soak
    };
    "1" = {
      name = "strawberry";
      ip = "192.168.142.22";
      # iftop: ~500Mb/s resync
      # dd: 220MB/s stable
    };
    # "2" = {
    #   name = "blueberry";
    #   ip = "192.168.142.24";
    # };
  };
in {

  networking.firewall.allowedTCPPorts = [
    port
  ];

  age.secrets = {
    tlshd-ca-crt = {
      file = ../../secrets/tlshd-ca-crt.age;
      mode = "0644";
    };
    tlshd-key = {
      file = ./. + "/../../secrets/tlshd-${config.networking.hostName}-key.age";
      mode = "0600";
    };
    tlshd-crt = {
      file = ./. + "/../../secrets/tlshd-${config.networking.hostName}-crt.age";
      mode = "0644";
    };
  };

  # DRBD will temporarily pass the sockets to a user space utility (tlshd, part
  # of the ktls-utils package) when establishing connections. tlshd will use the
  # keys configured in /etc/tlshd.conf to set up authentication and encryption.
  systemd.services.tlshd = {
    description = "Handshake service for kernel TLS consumers";
    documentation = [ "man:tlshd(8)" ];
    before = [ "remote-fs-pre.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ktls-utils}/bin/tlshd";
    };

    wantedBy = [ "remote-fs.target" ];
  };
  environment.etc."tlshd.conf" = {
    text = ''
      [authenticate.client]
      x509.truststore=${config.age.secrets.tlshd-ca-crt.path}
      x509.private_key=${config.age.secrets.tlshd-key.path}
      x509.certificate=${config.age.secrets.tlshd-crt.path}

      [authenticate.server]
      x509.truststore=${config.age.secrets.tlshd-ca-crt.path}
      x509.private_key=${config.age.secrets.tlshd-key.path}
      x509.certificate=${config.age.secrets.tlshd-crt.path}
    '';
  };

  systemd.tmpfiles.settings = {
    # DRBD likes to put lock files here
    # /var/lib/drbd/drbd-minor-1.lkbd
    "10-drbd-state"."/var/lib/drbd".d = {};
  };

  # use out-of-tree v9 kernel module
  boot.extraModulePackages = with config.boot.kernelPackages; [ drbd ];
  boot.blacklistedKernelModules = [ "drbd" ];
  boot.kernelModules = [ "drbd9" ];

  services.drbd = {
    enable = true;
    config = ''
      global {
        usage-count no;
      }
      common {
        net {
          protocol C;
          tls yes;
        }
      }
      resource "${resource}" {
        device minor 1;
        disk "${backDevice}";
        meta-disk internal;

        # options {
        #   auto-promote yes;
        #   quorum majority;
        # }

        disk {
          c-min-rate 55000; # KiB/s: bandwidth available for resync
          c-max-rate 60000; # KiB/s: total bandwidth available
        }

        ${(strings.concatMapAttrsStringSep "\n" (nodeId: node: ''
          on "${node.name}" {
            node-id ${nodeId};
          }
        '') nodes)}

        connection {
          ${(strings.concatMapAttrsStringSep "\n" (nodeId: node: ''
            host "${node.name}" address ${node.ip}:${toString port};
          '') nodes)}
        }
      }
    '';
  };

  # fix drbd module https://github.com/NixOS/nixpkgs/issues/347908#issuecomment-2407458908
  systemd.services.drbd = {
    path = with pkgs; [ drbd coreutils util-linux systemd ktls-utils ];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RemainAfterExit = "true";

      # debug:
      # ExecStart = "${pkgs.drbd}/bin/drbdadm up all -v";
      # ExecStop = "${pkgs.drbd}/bin/drbdadm down all -v";
    };
  };

  fileSystems = {
    "/data" = {
      device = "/dev/drbd/by-res/${resource}";
      fsType = "ext4";
    };
  };
}