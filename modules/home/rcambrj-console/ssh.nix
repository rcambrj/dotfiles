{ ... }:
let
  me = import ./me.nix;
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        # defaults
        ForwardAgent = false;
        ServerAliveCountMax = 3;
        Compression = false;
        AddKeysToAgent = "no";
        HashKnownHosts = false;
        ControlMaster = "no";
        ControlPersist = "no";
        TCPKeepAlive = true;
        ServerAliveInterval = 60;
        ConnectTimeout = 60;
      };
      "vm" = {
        HostName = "localhost";
        User = me.user;
        Port = 2222;
        # mitm unlikely to localhost
        UserKnownHostsFile = "/dev/null";
        StrictHostKeyChecking = false;
      };
      "cloudberry" = {
        # use IP because it runs the DNS server
        HostName =  "10.226.56.1";
        User = "nixos";
      };
      "blueberry" = {
        # kubernetes node
        HostName =  "blueberry.cambridge.me";
        User = "nixos";
      };
      "cranberry" = {
        # kubernetes node
        HostName =  "cranberry.cambridge.me";
        User = "nixos";
      };
      "minimal-intel" = {
        HostName =  "minimal-intel-nomad.local";
        User = "nixos";
        # this will boot on a variety of shapes
        UserKnownHostsFile = "/dev/null";
        StrictHostKeyChecking = false;
      };
      "minimal-raspi" = {
        HostName =  "minimal-raspi-nomad.local";
        User = "nixos";
        # this will boot on a variety of shapes
        UserKnownHostsFile = "/dev/null";
        StrictHostKeyChecking = false;
      };
      "elderberry" = {
        # 3d printer (dell wyse)
        HostName = "elderberry.cambridge.me";
        User = "nixos";
      };
      "orange" = {
        HostName = "orange-external.cambridge.me";
        User = "nixos";
      };
      "lemon" = {
        HostName = "lemon-external.cambridge.me";
        User = "nixos";
      };
      "lime" = {
        HostName = "lime-external.cambridge.me";
        User = "ubuntu";
      };
      "cherry" = {
        HostName =  "cherry-external.cambridge.me";
        User = "nixos";
      };
    };
  };
}
