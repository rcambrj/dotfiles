{ config, lib, perSystem, pkgs, ... }: with lib; {
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--advertise-routes=10.226.56.0/24"
    ];
    extraUpFlags = [
      "--snat-subnet-routes=false"
    ];
    useRoutingFeatures = "server";
  };
}