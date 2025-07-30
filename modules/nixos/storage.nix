{ config, lib, pkgs, ... }: with lib; let
  nodes = {
    "0" = {
      name = "cranberry";
      ip = "192.168.142.20";
      # dd: 480MB/s dropping to 170MB/s after heat soak
    };
    "1" = {
      name = "strawberry";
      ip = "192.168.142.22";
      # iftop: ~500Mb/s resync
      # dd: 220MB/s stable
    };
    # "2" = {
    #   name = "blueberry";
    #   ip = "192.168.142.24";
    # };
  };
in {

}