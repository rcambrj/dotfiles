#
# each server to back up the replicated store discretely.
# waste of storage? yes, but better than data loss.
#
{ config, lib, ... }:
with lib;
let
  cfg = config.services.server-backup;
in {
  options.services.server-backup = {
    enable = mkEnableOption "Server backup";
    paths = mkOption {
      default = [
        "/var/lib/glusterd"
        "/data"
      ];
    };
  };
  config = {
    age.secrets = {
      backup-bucket.file = ./. + "/../../secrets/${config.networking.hostName}-backup-bucket.age";
      backup-credentials.file = ./. + "/../../secrets/${config.networking.hostName}-backup-credentials.age";
      backup-encryption-key.file = ./. + "/../../secrets/${config.networking.hostName}-backup-encryption-key.age";
    };

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

      paths = cfg.paths;
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

        # specifics
        "jellyfin/data/metadata"
        "NzbDrone/MediaCover"
        "Radarr/MediaCover"
        "/data/media"
        "netbird-mgmt/data/GeoLite2-City_*.mmdb"
        "netbird-mgmt/data/geonames_*.db"
      ];
    };
  };
}