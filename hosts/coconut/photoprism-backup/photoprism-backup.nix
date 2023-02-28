{ config, pkgs, ... }: let
  mountPoint = "/mnt/photoprism";
in {
  users.groups.photoprism-backup = {};

  programs.fuse.userAllowOther = true;

  systemd.tmpfiles.settings = {
    "20-photoprism-backup-mount" = {
      "/mnt/photoprism" = {
        d = {
          user = "root";
          group = "photoprism-backup";
          mode = "0440";
        };
      };
    };
  };

  programs.ssh.knownHostsFiles = [
    ./photoprism_known_hosts
  ];

  systemd.services.photoprism-mount = {
    script = ''
      cat ${config.age.secrets.photoprism-sftp-password.path} | ${pkgs.sshfs}/bin/sshfs \
        -f \
        -o allow_other \
        -o password_stdin \
        -o ro \
        -o reconnect \
        -o idmap=user \
        p14463@photoprism.pikapod.net:/ \
        ${mountPoint}
    '';
  };

  services.restic.backups.photoprism = {
    timerConfig = {
      OnCalendar = "weekly";
      RandomizedDelaySec = "2h";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-weekly 6"
      "--keep-monthly 6"
      "--keep-yearly 2"
    ];

    initialize = true;

    repositoryFile  = config.age.secrets.photoprism-backup-bucket.path;
    passwordFile    = config.age.secrets.photoprism-backup-encryption-key.path;
    environmentFile = config.age.secrets.photoprism-backup-credentials.path;

    paths = [ "/mnt/photoprism" ];
  };

  systemd.services.restic-backups-photoprism = {
    requires = [ "photoprism-mount.service" ];
    after = [ "photoprism-mount.service" ];
    bindsTo = [ "photoprism-mount.service" ];
  };
}