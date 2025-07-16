# requires secrets:
# - backup-bucket
# - backup-encryption-key
# - backup-credentials

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
    ];
  };
}