{ config, ... }: {
  services.restic.backups.main = {
    timerConfig = {
      OnCalendar = "04:00";
      Persistent = true;
      RandomizedDelaySec = "2h";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 6"
      "--keep-yearly 2"
    ];

    initialize = true;

    repositoryFile  = config.age.secrets.backup-bucket.path;
    passwordFile    = config.age.secrets.backup-encryption-key.path;
    environmentFile = config.age.secrets.backup-credentials.path;

    paths = [
      "/var/lib"
      "/data"
    ];
    exclude = [
      # generics
      ".cache"
      ".esphome"
      ".git"
      ".platformio"
      "*.log"
      "cache"
      "log.txt"
      "logrotate.status"
      "logs.db"
      "logs"
      "jellyfin/metadata"
      "NzbDrone/MediaCover"
      "Radarr/MediaCover"

      # specifics
      "/data/media"
      "/var/lib/alloy"
      "/var/lib/cni"
      "/var/lib/etcd-store"
      "/var/lib/kubelet"
      "/var/lib/machines"
      "/var/lib/nixos"
      "/var/lib/portables"
      "/var/lib/rancher"
      "/var/lib/systemd"
    ];
  };
}