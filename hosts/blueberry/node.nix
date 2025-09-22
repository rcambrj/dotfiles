{ config, flake, inputs, lib, pkgs, ... }: with lib; {
  imports = [
    flake.nixosModules.disk-savers
    flake.nixosModules.kubernetes-manifests
    flake.nixosModules.kubernetes-node
    flake.nixosModules.storage
  ];

  services.gluster-node = {
    enable = true;
    disknode = true;
  };
  services.kubernetes-node = {
    enable = true;
    role = "server";
    k3sExtraFlags = [
      # has the gluster volume at /data
      "--node-label=gluster-volume-mount/configured=true"
      "--node-taint=gluster-volume-mount=absent:NoExecute"

      # https://docs.k3s.io/networking/networking-services#creating-servicelb-node-pools
      "--node-label=svccontroller.k3s.cattle.io/enablelb=true"
    ];
  };
  services.kubernetes-manifests.enable = false;
  disk-savers.etcd-store = {
    # writes about 100-200KB/s constantly (17GB/day)
    # or with rsync, 200MB every...
    syncEvery = "3h";
    targetDir = "/var/lib/rancher/k3s/server/db/etcd/member";
    targetMountName = "var-lib-rancher-k3s-server-db-etcd-member";
    diskDir = "/var/lib/etcd-store";
  };

  systemd.services.k3s = {
    bindsTo = [ "${config.disk-savers.etcd-store.targetMountName}.mount" ];
    requires = [ "${config.disk-savers.etcd-store.targetMountName}.mount" ];
    after = [ "${config.disk-savers.etcd-store.targetMountName}.mount" ];
    postStop = ''
      ${pkgs.systemd}/bin/systemctl start disk-saver-etcd-store.service
    '';
  };
}