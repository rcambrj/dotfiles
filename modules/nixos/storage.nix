# https://linbit.com/drbd-user-guide/drbd-guide-9_0-en/
# https://manpages.debian.org/testing/drbd-utils/drbd.conf-9.0.5.en.html
#
# https://linbit.com/drbd-user-guide/users-guide-drbd-8-4/
# https://manpages.debian.org/testing/drbd-utils/drbd.conf-8.4.5.en.html
#
# first disk setup:
# https://linbit.com/drbd-user-guide/drbd-guide-9_0-en/#s-first-time-up
# if needed, wipe existing filesystem (ctrl+c after some seconds)
# dd if=/dev/zero of=/dev/pool/DATA
#
# TLS is disabled because DRBD fails to start with:
# Parse error: 'an option keyword' expected, but got 'tls'
#
# drbd.conf uses the 8.4 config layout, because 9.27 complains about 9.0 layout:
# Parse error: 'disk | device | address | meta-disk | flexible-meta-disk' expected, but got 'node-id'
#
# despite:
# drbdadm --version
# DRBDADM_VERSION=9.27.0
#
# unfortunately:
# cat /proc/drbd
# version: 8.4.11
#
# according to nix, boot.kernelPackages.drbd should be 9.2.12
#
{ config, lib, pkgs, ... }: with lib; let
  port = 7788;
  resource = "r0";
  drbdDevice = "/dev/drbd1";
  backDevice = "/dev/pool/DATA";
  nodes = {
    "0" = {
      name = "cranberry";
      ip = "192.168.142.20";
      rate = "50M";
    };
    "1" = {
      name = "strawberry";
      ip = "192.168.142.22";
      rate = "20M";
    };
    # "2" = {
    #   name = "blueberry";
    #   ip = "192.168.142.24";
    #   # rate = ???;
    # };
  };
in {

  networking.firewall.allowedTCPPorts = [
    port
  ];

  age.secrets = {
    # tlshd-ca-crt.file = ../../secrets/tlshd-ca-crt.age;
    # tlshd-key.file = ./. + "/../../secrets/tlshd-${config.networking.hostName}-key.age";
    # tlshd-crt.file = ./. + "/../../secrets/tlshd-${config.networking.hostName}-crt.age";
    drbd-secret.file = ../../secrets/drbd-secret.age;
  };

  # DRBD will temporarily pass the sockets to a user space utility (tlshd, part
  # of the ktls-utils package) when establishing connections. tlshd will use the
  # keys configured in /etc/tlshd.conf to set up authentication and encryption.
  # systemd.services.tlshd = {
  #   description = "Handshake service for kernel TLS consumers";
  #   documentation = [ "man:tlshd(8)" ];
  #   before = [ "remote-fs-pre.target" ];

  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.ktls-utils}/bin/tlshd";
  #   };

  #   wantedBy = [ "remote-fs.target" ];
  # };
  # environment.etc."tlshd.conf" = {
  #   text = ''
  #     [authenticate.client]
  #     x509.truststore=${config.age.secrets.tlshd-ca-crt.path}
  #     x509.private_key=${config.age.secrets.tlshd-key.path}
  #     x509.certificate=${config.age.secrets.tlshd-crt.path}

  #     [authenticate.server]
  #     x509.truststore=${config.age.secrets.tlshd-ca-crt.path}
  #     x509.private_key=${config.age.secrets.tlshd-key.path}
  #     x509.certificate=${config.age.secrets.tlshd-crt.path}
  #   '';
  # };

  systemd.tmpfiles.settings = {
    # DRBD likes to put lock files here
    # /var/lib/drbd/drbd-minor-1.lkbd
    "10-drbd-state"."/var/lib/drbd".d = {};
  };


  services.drbd = {
    enable = true;
    config = ''
      include "${config.age-template.files.drbd-config.path}";
    '';
  };

  # fix drbd module https://github.com/NixOS/nixpkgs/issues/347908#issuecomment-2407458908
  systemd.services.drbd = {
    path = with pkgs; [ drbd coreutils util-linux systemd ];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RemainAfterExit = "true";
    };
  };

  age-template.files.drbd-config = {
    vars = {
      secret = config.age.secrets.drbd-secret.path;
    };
    content = ''
      global {
        usage-count no;
      }
      common {
        net {
          protocol C;
        }
        syncer {
          rate 64M;
        }
      }
      resource "${resource}" {
        net {
          # tls yes;
          # see comments top of module

          # cram-hmac-alg sha256;
          # shared-secret "$secret";
          # causes:
          # drbd Failure: (126) UnknownMandatoryTag
        }
        # options {
        #   auto-promote yes;
        # }

        ${(strings.concatMapAttrsStringSep "\n" (nodeId: node: ''
          on ${node.name} {
            device ${drbdDevice};
            disk ${backDevice};
            meta-disk internal;
            address ${node.ip}:${toString port};
          }
        '') nodes)}
      }
    '';
  };

  # systemd.mounts = [
  #   {
  #     what = "/dev/drbd/by-res/${resource}";
  #     where = "/data";
  #     requires = [ "drbd.service" ];
  #     wantedBy = [ "multi-user.target" ];
  #   }
  # ];
  fileSystems = {
    "/data" = {
      device = "/dev/drbd/by-res/${resource}";
      fsType = "ext4";
    };
  };
}