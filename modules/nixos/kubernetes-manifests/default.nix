args@{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.kubernetes-manifests;
  argocd = import ./argocd.nix;
  secrets = import ./secrets.nix;
in {

  options.services.kubernetes-manifests = {
    enable = mkEnableOption "Put manifests into /var/lib/rancher/k3s/server/manifests";
  };

  config = mkIf cfg.enable ((argocd args) // (secrets args));
}