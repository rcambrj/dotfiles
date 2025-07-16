{ config, ... }: {
  # Longhorn is installed onto kubernetes via ArgoCD
  # these are the host-level dependencies

  # RWO
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };
  # RWX
  services.nfs.server = {
    enable = true;
  };

}