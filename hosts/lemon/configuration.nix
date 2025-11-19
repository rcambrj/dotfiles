{ config, flake, inputs, lib, modulesPath, pkgs, perSystem, ... }: {
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"

    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.disko-standard
    flake.nixosModules.common
    flake.nixosModules.cloud-vps
    flake.nixosModules.netbird
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
    extraConfig = ''
      MulticastDNS=false
      DNS=1.1.1.1#cloudflare-dns.com 8.8.8.8#dns.google 1.0.0.1#cloudflare-dns.com 8.8.4.4#dns.google 2606:4700:4700::1111#cloudflare-dns.com 2001:4860:4860::8888#dns.google 2606:4700:4700::1001#cloudflare-dns.com 2001:4860:4860::8844#dns.google
      [Resolve]
      DNS=127.0.0.62
      Domains=~cambridge.me ~cambridge.netbird
    '';
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

  # services.netbird.package = lib.mkForce (perSystem.self.netbird.override {
  #   broken = true;
  # });
}