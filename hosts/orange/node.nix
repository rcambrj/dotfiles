{ config, flake, inputs, lib, pkgs, ... }: with lib; let
  iface = config.services.netbird.clients.default.interface;
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

      # send traffic over netbird
      "--flannel-iface=${iface}"
      "--node-ip=${nodeIP}"

      # 127.0.0.1:53 uses DNS resolvers provided by netbird (we want that)
      # but core-dns has a different 127.0.0.1, so use the nodeIP
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