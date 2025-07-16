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
      ".platformio"
      ".esphome"
      ".git"
      "*.log"
      "logs"
      "logs.db"
      "log.txt"
      "/var/lib/longhorn/replicas"
      "/var/lib/media"
      "/var/lib/jellyfin/metadata"
      "/var/lib/radarr/.config/Radarr/MediaCover"
      "/var/lib/radarr/.config/NzbDrone/MediaCover"
      "/var/lib/nzbget/downloads"
      "/var/lib/transmission/watchdir"
      "/var/lib/transmission/Downloads"
      "/var/lib/transmission/.incomplete"
      "/var/lib/pia-vpn"
    ];
  };
}