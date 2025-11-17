{ ... }:
let
  me = import ./me.nix;
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        # defaults
        extraOptions = {
          ForwardAgent = "no";
          ServerAliveCountMax = "3";
          Compression = "no";
          AddKeysToAgent = "no";
          HashKnownHosts = "no";
          ControlMaster = "no";
          ControlPersist = "no";
          TCPKeepAlive = "yes";
          ServerAliveInterval = "60";
          ConnectTimeout = "60";
        };
      };
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
      "cloudberry" = {
        # use IP because it runs the DNS server
        hostname =  "192.168.142.1";
        user = "nixos";
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
      "orange" = {
        # oracle cloud free aarch64
        hostname = "orange-external.cambridge.me";
        user = "nixos";
      };
      "lemon" = {
        # oracle cloud free aarch64
        hostname = "lemon-external.cambridge.me";
        user = "nixos";
      };
    };
  };
}