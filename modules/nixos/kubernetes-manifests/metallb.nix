{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.kubernetes-manifests;
in {
  options = {};
  config = mkIf cfg.enable ({
    services.k3s.manifests."10-metallb-ns".content = {
      apiVersion = "v1";
      kind = "Namespace";
      metadata.name = "metallb-system";
    };

    services.k3s.manifests."20-metallb".content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChart";
      metadata = {
        name = "metallb";
        namespace = "metallb-system";
        finalizers = [
          "wrangler.cattle.io/on-helm-chart-remove"
        ];
      };
      spec = {
        bootstrap = true;
        # https://artifacthub.io/packages/helm/metallb/metallb
        repo = "https://metallb.github.io/metallb";
        chart = "metallb";
        version = "0.15.2";
        targetNamespace = "metallb-system";
        valuesContent = builtins.toJSON {
          controller.tolerations = [{
            # taint used by gluster-mount-watcher & control-plane
            key = "CriticalAddonsOnly";
            operator = "Exists";
          }];
          controller.nodeSelector = { metallb-candidate = "true"; };
          speaker.nodeSelector = { metallb-candidate = "true"; };
        };
      };
    };

    services.k3s.manifests."30-metallb-crs".content = [
      {
        apiVersion = "metallb.io/v1beta1";
        kind = "IPAddressPool";
        metadata = {
          name = "default";
          namespace = "metallb-system";
        };
        spec.addresses = ["10.226.56.50/32"];
      }
      {
        apiVersion = "metallb.io/v1beta1";
        kind = "L2Advertisement";
        metadata = {
          name = "default";
          namespace = "metallb-system";
        };
        spec.ipAddressPools = ["default"];
      }
    ];
  });
}
