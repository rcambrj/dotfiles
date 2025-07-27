{ config, lib, pkgs, ... }: let
  package = pkgs.seaweedfs;
  masterPortHTTP =  9333; # disabled
  masterPortGRPC = 19333;
  volumePortHTTP =  8080; # disabled
  volumePortGRPC = 18080;
  filerPortHTTP  =  8888; # disabled
  filerPortGRPC  = 18888;
  masters = "cranberry:${toString masterPortHTTP}.${toString masterPortGRPC}";
in with lib; {
  environment.systemPackages = [ package ];

  networking.firewall.allowedTCPPorts = [
    # permit access to encrypted (mutual TLS) GRPC service
    # don't expose insecure HTTP
    # spin up `weed admin` GUI in kubernetes
    masterPortGRPC
    volumePortGRPC
    filerPortGRPC
  ];

  age.secrets = {
    # populate out/ca.key & out/ca.crt & chmod 400
    # certstrap request-cert --common-name cranberry-master
    # certstrap sign --expires "10 years" --CA ca cranberry-master

    seaweedfs-ca-crt = {
      file     = ../../secrets/seaweedfs-ca-crt.age;
      mode = "444";
    };
    seaweedfs-master-key = {
      file = ./. + "/../../secrets/${config.networking.hostName}-seaweedfs-master-key.age";
      owner = "seaweedfs";
      group = "seaweedfs";
    };
    seaweedfs-master-crt = {
      file = ./. + "/../../secrets/${config.networking.hostName}-seaweedfs-master-crt.age";
      owner = "seaweedfs";
      group = "seaweedfs";
    };
    seaweedfs-volume-key = {
      file = ./. + "/../../secrets/${config.networking.hostName}-seaweedfs-volume-key.age";
      owner = "seaweedfs";
      group = "seaweedfs";
    };
    seaweedfs-volume-crt = {
      file = ./. + "/../../secrets/${config.networking.hostName}-seaweedfs-volume-crt.age";
      owner = "seaweedfs";
      group = "seaweedfs";
    };
    seaweedfs-filer-key = {
      file  = ./. + "/../../secrets/${config.networking.hostName}-seaweedfs-filer-key.age";
      owner = "seaweedfs";
      group = "seaweedfs";
    };
    seaweedfs-filer-crt = {
      file  = ./. + "/../../secrets/${config.networking.hostName}-seaweedfs-filer-crt.age";
      owner = "seaweedfs";
      group = "seaweedfs";
    };
    seaweedfs-jwt-read-key = {
      file    = ../../secrets/seaweedfs-jwt-read-key.age;
      owner = "seaweedfs";
      group = "seaweedfs";
    };
    seaweedfs-jwt-write-key = {
      file   = ../../secrets/seaweedfs-jwt-write-key.age;
      owner = "seaweedfs";
      group = "seaweedfs";
    };
  };

  age-template.files.seaweedfs-security-toml = {
    path = "/etc/seaweedfs/security.toml";
    owner = "seaweedfs";
    group = "seaweedfs";
    vars = {
      jwtread  = config.age.secrets.seaweedfs-jwt-read-key.path;
      jwtwrite = config.age.secrets.seaweedfs-jwt-write-key.path;
    };
    content = ''
      [jwt.signing]
      key = "$jwtwrite"

      [jwt.filer_signing]
      key = "$jwtread"

      [grpc]
      ca = "${config.age.secrets.seaweedfs-ca-crt.path}"

      [grpc.master]
      key  = "${config.age.secrets.seaweedfs-master-key.path}"
      cert = "${config.age.secrets.seaweedfs-master-crt.path}"

      [grpc.volume]
      key  = "${config.age.secrets.seaweedfs-volume-key.path}"
      cert = "${config.age.secrets.seaweedfs-volume-crt.path}"

      [grpc.filer]
      key  = "${config.age.secrets.seaweedfs-filer-key.path}"
      cert = "${config.age.secrets.seaweedfs-filer-crt.path}"

      [access]
      # `weed volume` doesn't have -disableAccess
      # the switch is here instead for some reason
      ui = false
    '';
  };

  users.users.seaweedfs = {
    uid = config.ids.uids.ceph;
    group = "seaweedfs";
    isSystemUser = true;
  };
  users.groups.seaweedfs = {
    gid = config.ids.uids.ceph;
  };

  systemd.tmpfiles.settings."seaweedfs"."/var/lib/seaweedfs/data".d = {
    user = "seaweedfs";
    group = "seaweedfs";
    mode = "0700";
  };

  systemd.services.seaweedfs-master = rec {
    description = "SeaweedFS";
    wants = [ "network.target" ];
    after = wants;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = rec {
      Restart = "on-failure";
      Type = "exec";
      User = "seaweedfs";
      Group = "seaweedfs";
      ConfigurationDirectory = "seaweedfs/master";
      RuntimeDirectory = ConfigurationDirectory;
      RuntimeDirectoryPreserve = "restart";
      WorkingDirectory = "/run/${RuntimeDirectory}";
      ExecStart = builtins.concatStringsSep " " [
        # https://github.com/seaweedfs/seaweedfs/blob/master/weed/command/master.go
        "${getExe package} master"
        "-port=${toString masterPortHTTP}"
        "-disableHttp"
        "-port.grpc=${toString masterPortGRPC}"
        "-ip=${config.networking.hostName}"
        "-ip.bind=0.0.0.0"
        # "-peers=${masters}" # disable while there is only one node
        "-mdir=."
        "-volumeSizeLimitMB=1000"
        "-defaultReplication=000"
      ];
    };
  };

  systemd.services.seaweedfs-volume = rec {
    description = "SeaweedFS";
    wants = [ "network.target" ];
    after = wants;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = rec {
      Restart = "on-failure";
      Type = "exec";
      User = "seaweedfs";
      Group = "seaweedfs";
      ConfigurationDirectory = "seaweedfs/volume";
      RuntimeDirectory = ConfigurationDirectory;
      RuntimeDirectoryPreserve = "restart";
      WorkingDirectory = "/run/${RuntimeDirectory}";
      ExecStart = builtins.concatStringsSep " " [
        # https://github.com/seaweedfs/seaweedfs/blob/master/weed/command/volume.go
        "${getExe package} volume"
        "-port=${toString volumePortHTTP}"
        "-port.grpc=${toString volumePortGRPC}"
        "-ip=${config.networking.hostName}"
        "-ip.bind=0.0.0.0"
        # "-mserver=${masters}" # disable while there is only one node
        "-dataCenter=home" # TODO: this should be configurable
        "-rack=blue" # TODO: this should be configurable
        "-max=0"
        "-minFreeSpace=10GiB"
        "-dir=/var/lib/seaweedfs/data"
      ];
    };
  };

  systemd.services.seaweedfs-filer = rec {
    description = "SeaweedFS";
    wants = [ "network.target" ];
    after = wants;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = rec {
      Restart = "on-failure";
      Type = "exec";
      User = "seaweedfs";
      Group = "seaweedfs";
      ConfigurationDirectory = "seaweedfs/filer";
      RuntimeDirectory = ConfigurationDirectory;
      RuntimeDirectoryPreserve = "restart";
      WorkingDirectory = "/run/${RuntimeDirectory}";
      ExecStart = builtins.concatStringsSep " " [
        # https://github.com/seaweedfs/seaweedfs/blob/master/weed/command/filer.go
        "${getExe package} filer"
        "-port=${toString filerPortHTTP}"
        "-disableHttp"
        "-port.grpc=${toString filerPortGRPC}"
        "-ip=${config.networking.hostName}"
        "-ip.bind=0.0.0.0"
        "-master=${masters}"
        "-dataCenter=home" # TODO: this should be configurable
        "-rack=blue" # TODO: this should be configurable
      ];
    };
  };
}