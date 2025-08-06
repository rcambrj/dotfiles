{ flake, ... }: {
  imports = [
    flake.nixosModules.primary-wan
  ];

  systemd.targets.downloads-enabled = {
    wants = [
      # "restic-backups-main.service" # backup comes up on a schedule
    ];
  };

  systemd.services.restic-backups-main.after = [ "primary-wan.service" ];
  systemd.services.restic-backups-main.requisite = [ "primary-wan.service" ];
}