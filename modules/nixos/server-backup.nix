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

    paths = [ "/var/lib" ];
    exclude = [
      # generics
      ".esphome"
      ".git"
      ".platformio"
      "*.log"
      "log.txt"
      "logrotate.status"
      "logs.db"
      "logs"

      # specifics
      "/var/lib/alloy"
      "/var/lib/cni"
      "/var/lib/kubelet"
      "/var/lib/longhorn"
      "/var/lib/machines"
      "/var/lib/nfs"
      "/var/lib/nixos"
      "/var/lib/portables"
      "/var/lib/rancher"
      "/var/lib/systemd"

      # deprecated
      "/var/lib/jellyfin/metadata"
      "/var/lib/media"
      "/var/lib/nzbget/downloads"
      "/var/lib/pia-vpn"
      "/var/lib/radarr/.config/NzbDrone/MediaCover"
      "/var/lib/radarr/.config/Radarr/MediaCover"
      "/var/lib/transmission/.incomplete"
      "/var/lib/transmission/Downloads"
      "/var/lib/transmission/watchdir"
    ];
  };
}