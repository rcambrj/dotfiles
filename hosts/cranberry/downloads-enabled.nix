{ flake, ... }: {
  imports = [
    flake.nixosModules.primary-wan
  ];

  systemd.targets.downloads-enabled = {
    wants = [
      # "restic-backups-main.service" # backup comes up on a schedule
      "jackett.service"
      "nzbget.service"
      "transmission.service"
    ];
  };

  systemd.services.restic-backups-main.after = [ "primary-wan.service" ];
  systemd.services.restic-backups-main.requisite = [ "primary-wan.service" ];
  systemd.services.jackett.after = [ "primary-wan.service" ];
  systemd.services.jackett.bindsTo = [ "primary-wan.service" ];
  systemd.services.nzbget.after = [ "primary-wan.service" ];
  systemd.services.nzbget.bindsTo = [ "primary-wan.service" ];
  systemd.services.transmission.after = [ "primary-wan.service" ];
  systemd.services.transmission.bindsTo = [ "primary-wan.service" ];
}