{ flake, inputs, modulesPath, ... }: {
  imports = [
    # "${toString modulesPath}/profiles/qemu-guest.nix"
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

    inputs.agenix-template.nixosModules.default

    flake.nixosModules.base
    flake.nixosModules.access-server
    flake.nixosModules.disko-standard
    flake.nixosModules.common
    flake.nixosModules.cloud-vps
    ./netbird.nix
    ./node.nix
  ];

  networking.hostName = "orange";


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
}