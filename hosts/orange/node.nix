{ config, flake, inputs, lib, pkgs, ... }: with lib; {
  imports = [
    flake.nixosModules.kubernetes-manifests
    flake.nixosModules.kubernetes-node
    flake.nixosModules.storage
  ];

  services.gluster-node = {
    enable = true;
    disknode = false;
    openFirewallOnInterface = config.services.netbird.clients.default.interface;
  };
  services.kubernetes-node = {
    enable = true;
    role = "server";
    strategy = "join";
    openFirewallOnInterface = config.services.netbird.clients.default.interface;
  };
  services.kubernetes-manifests.enable = false;

  services.k3s.extraFlags = [
    # control-plane only
    "--node-taint=node-role.kubernetes.io/master:NoSchedule"

    # send traffic over netbird
    "--flannel-iface=netbird"
  ];
}