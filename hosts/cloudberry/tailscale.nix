{ config, lib, perSystem, pkgs, ... }: with lib; {
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--advertise-routes=10.226.56.0/24"
      # let dnsmasq own /etc/resolv.conf; tailscaled keeps MagicDNS reachable
      # via 100.100.100.100, which dnsmasq forwards to for *.ts.net.
      "--accept-dns=false"
    ];
    extraUpFlags = [
      "--snat-subnet-routes=false"
    ];
    useRoutingFeatures = "server";
  };
}