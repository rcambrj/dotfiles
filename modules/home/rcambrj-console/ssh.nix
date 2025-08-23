{ ... }:
let
  me = import ./me.nix;
in {
  programs.ssh = {
    enable = true;
    extraConfig = ''
      TCPKeepAlive = yes
      ServerAliveInterval = 60
      ConnectTimeout = 60
    '';
    matchBlocks = {
      "vm" = {
        hostname = "localhost";
        user = me.user;
        port = 2222;
        extraOptions = {
          # mitm unlikely to localhost
          UserKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
        };
      };
      "router" = {
        hostname =  "192.168.142.1";
        user = "root";
      };
      "blueberry" = {
        # kubernetes node
        hostname =  "blueberry.cambridge.me";
        user = "nixos";
      };
      "cranberry" = {
        # kubernetes node
        hostname =  "cranberry.cambridge.me";
        user = "nixos";
      };
      "minimal-intel" = {
        hostname =  "minimal-intel-nomad.local";
        user = "nixos";
        extraOptions = {
          # this will boot on a variety of shapes
          UserKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
        };
      };
      "minimal-raspi" = {
        hostname =  "minimal-raspi-nomad.local";
        user = "nixos";
        extraOptions = {
          # this will boot on a variety of shapes
          UserKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
        };
      };
      "elderberry" = {
        # 3d printer (dell wyse)
        hostname = "elderberry.cambridge.me";
        user = "nixos";
      };
      "lime" = {
        # gullo's shitbox
        hostname = "51.255.83.152";
        user = "root";
        port = 15120;
      };
      "orange" = {
        # oracle cloud free aarch64
        hostname = "orange-external.cambridge.me";
        user = "nixos";
      };
    };
  };
}