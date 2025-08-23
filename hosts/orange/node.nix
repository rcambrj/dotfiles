{ config, flake, inputs, lib, pkgs, ... }: with lib; let
  iface = config.services.netbird.clients.default.interface;
in {
  imports = [
    flake.nixosModules.kubernetes-manifests
    flake.nixosModules.kubernetes-node
    flake.nixosModules.storage
  ];

  services.gluster-node = {
    enable = true;
    disknode = false;
    openFirewallOnInterface = iface;
  };
  services.kubernetes-node = {
    enable = true;
    role = "server";
    openFirewallOnInterface = iface;
    k3sExtraFlags = [
      # control-plane only
      "--node-taint=node-role.kubernetes.io/master:NoSchedule"

      # send traffic over netbird
      "--flannel-iface=${iface}"
      "--node-external-ip=100.68.241.89"
    ];
  };
  services.kubernetes-manifests.enable = false;
}