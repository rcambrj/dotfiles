{ config, lib, pkgs, ... }: let
  package = seaweedfs;
  masterPort = 9333;
  volumePort = 8080;
  filterPort = 8888;
  webdavPort = 8333;
in with lib; {
  environment.systemPackages = with pkgs; [ package ];

  environment.etc."seaweedfs/security.toml".text = {
    grpc.ca = "seaweedfs-rcambrj";
    "grpc.master" = {
      cert = "";
      key = "";
    };
    "grpc.volume" = {
      cert = "";
      key = "";
    };
    "grpc.filer" = {
      cert = "";
      key = "";
    };
    "grpc.client" = {
      cert = "";
      key = "";
    };
    "grpc.msg_broker" = {
      cert = "";
      key = "";
    };
  };

  systemd.services.seaweedfs-master = rec {
    description = "SeaweedFS";
    wants = [ "network.target" ];
    after = wants;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = rec {
      Restart = "on-failure";
      Type = "exec";
      ConfigurationDirectory = "seaweedfs/master";
      RuntimeDirectory = ConfigurationDirectory;
      RuntimeDirectoryPreserve = "restart";
      WorkingDirectory = "/run/${RuntimeDirectory}";
      ExecStart = builtins.concatStringsSep " " [
        # https://github.com/seaweedfs/seaweedfs/blob/master/weed/command/master.go
        "${getExe package} master"
        "-port=${masterPort}"
        "-ip=${config.networking.hostName}"
        # "-peers=192.168.42.24:${masterPort}"
        "-mdir=."
      ];
    };
  };
}