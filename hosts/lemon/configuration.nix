{ config, flake, inputs, lib, modulesPath, pkgs, perSystem, ... }: {
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"

    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.disko-standard
    flake.nixosModules.common
    flake.nixosModules.cloud-vps
    flake.nixosModules.tailscale
    flake.nixosModules.server-backup
    ./http
  ];

  networking.hostName = "lemon";
  nixpkgs.hostPlatform = "aarch64-linux";
  disko.devices.disk.disk1.device = "/dev/sda";

  systemd.network.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;
  services.resolved = {
    enable = true;
    llmnr = "false";
    settings.Resolve = {
        MulticastDNS = false;
        # TODO: determine whether this is needed with tailscale
        # DNS = concatStringsSep " " [
        #   "1.1.1.1#cloudflare-dns.com"
        #   "8.8.8.8#dns.google"
        #   "1.0.0.1#cloudflare-dns.com"
        #   "8.8.4.4#dns.google"
        #   "2606:4700:4700::1111#cloudflare-dns.com"
        #   "2001:4860:4860::8888#dns.google"
        #   "2606:4700:4700::1001#cloudflare-dns.com"
        #   "2001:4860:4860::8844#dns.google"
        #   "100.100.100.100"
        # ];
        # Domains = "~cambridge.me ~tail7ee3a3.ts.net";
    };
  };
  systemd.network.networks = {
    "10-wired" = {
      matchConfig.Name = "e*";
      dhcpV4Config.UseDNS = "no";
      dhcpV6Config.UseDNS = "no";
      networkConfig = {
        LinkLocalAddressing = "no";
        MulticastDNS = "no";
        LLMNR = "no";
        DHCP = "yes";
      };
    };
  };

  services.server-backup = {
    enable = false;
    paths = [
      # nothing to back up
    ];
  };
}