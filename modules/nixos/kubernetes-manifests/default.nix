args@{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.kubernetes-manifests;
in {
  imports = [
    ./argocd.nix
    # ./metallb.nix
    ./secrets.nix
  ];

  options.services.kubernetes-manifests = {
    enable = mkEnableOption "Puts manifests into /var/lib/rancher/k3s/server/manifests";
  };
  config = {};
}