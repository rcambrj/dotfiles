{ config, flake, inputs, lib, pkgs, ... }: with lib; let
  iface = config.services.tailscale.interfaceName;
  nodeIP = "100.121.0.11";
  dnsUpstream = "10.226.56.1";
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
    role = "singular-server";
    openFirewallOnInterface = iface;
    k3sExtraFlags = [
      "--node-taint=CriticalAddonsOnly:NoExecute"

      # send traffic over VPN
      "--flannel-iface=${iface}"
      "--node-ip=${nodeIP}"

      # host has DNS magic for hostnames across VPN and beyond (home LAN)
      "--resolv-conf=${pkgs.writeTextFile {
        name = "k3s-resolv.conf";
        text = ''
          nameserver ${dnsUpstream}
        '';
      }}"
    ];
  };
  services.kubernetes-manifests.enable = true;
}