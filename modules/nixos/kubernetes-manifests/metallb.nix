{ config, lib, pkgs, ... }: with lib; let
  chartVersion = "0.15.2";

  cfg = config.services.kubernetes-manifests;
in {
  options = {};
  config = mkIf cfg.enable {
    # TODO: move this into yaml

    services.k3s.manifests."10-metallb-ns".content = {
      apiVersion = "v1";
      kind = "Namespace";
      metadata.name = "metallb-system";
    };

    services.k3s.manifests."20-metallb".content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChart";
      metadata = {
        namespace = "metallb-system";
        name = "metallb";
        finalizers = [
          "wrangler.cattle.io/on-helm-chart-remove"
        ];
      };
      spec = {
        targetNamespace = "metallb-system";
        createNamespace = true;
        version = chartVersion;
        chart = "metallb";
        repo = "https://metallb.github.io/metallb";
      };
    };
  };
}