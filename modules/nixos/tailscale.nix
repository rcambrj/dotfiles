{ config, lib, perSystem, pkgs, ... }: with lib; {
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--accept-routes"
    ];
    extraUpFlags = [];
    useRoutingFeatures = "client";
  };
}