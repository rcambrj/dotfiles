# get started (stateful)
#
# mkfs.xfs -f /dev/pool/DATA
#
# gluster peer probe cranberry.cambridge.me
# gluster peer probe strawberry.cambridge.me
# gluster peer probe blueberry.cambridge.me
#
# gluster volume create gv0 \
#   replica 3 arbiter 1 \
#   cranberry.cambridge.me:/mnt/gluster/brick \
#   strawberry.cambridge.me:/mnt/gluster/brick \
#   blueberry.cambridge.me:/var/lib/glusterd-brick-arbiter \
#   force
#
# gluster volume set gv0 client.ssl on
# gluster volume set gv0 server.ssl on
# gluster volume set gv0 ssl.cipher-list 'HIGH:!SSLv2'
# gluster volume set gv0 ssl.certificate-depth 1
# gluster volume set gv0 auth.ssl-allow *
#
# gluster volume start gv0
#
#
{ config, lib, pkgs, ... }: with lib; let
  nodes = [
    # iftop cranberry to strawberry: ~500Mb/s resync
    {
      fqdn = "cranberry.cambridge.me";
      # dd: 480MB/s dropping to 170MB/s after heat soak
    }
    {
      fqdn = "strawberry.cambridge.me";
      # dd: 220MB/s stable
    }
    {
      fqdn = "blueberry.cambridge.me";
    }
  ];
  cfg = config.services.gluster-node;
in {
  options.services.gluster-node = {
    enable = mkEnableOption "Start a gluster node and/or mount the distributed disk";
    disknode = mkOption {
      type = types.bool;
      description = ''
        If true, this node is assumed to have a `backendDevice` which will serve
        as a replica in the gluster replica set. If false, the `backendDevice`
        is not mounted, but the gluster service is still brought up. In both
        cases the distributed volume is mounted at `distributedVolumeMountPoint`
        and the node can be joined to the cluster for voting rights.
      '';
      default = true;
    };
    backendDevice = mkOption {
      type = types.str;
      description = "The xfs partition which serves as the backend. This should be a block device";
      default = "/dev/pool/DATA";
    };
    backendMountPoint = mkOption {
      type = types.str;
      description = "The mount point for the backend. Doesn't matter where this is";
      default = "/mnt/gluster";
    };
    backendMountName = mkOption {
      type = types.str;
      description = "The name of the mount, as escaped by systemd-escape";
      default = "mnt-gluster.mount";
    };
    distributedVolumeMountPoint = mkOption {
      type = types.str;
      description = "The mount point for the distributed volume. This is the bit you consume";
      default = "/data";
    };
    distributedVolumeMountName = mkOption {
      type = types.str;
      description = "The name of the mount, as escaped by systemd-escape";
      default = "data.mount";
    };
    mountLocalhost = mkOption {
      type = types.bool;
      description = ''
        Whether to mount the distributed volume at distributedVolumeMountPoint
        via the local gluster service or over the network via the disk nodes. If
        true, this node must join the cluster, it need not be a replica (but can be)
      '';
      default = true;
    };
    openFirewallOnInterface = mkOption {
      type = types.str;
      default = "";
      description = "If specified, only open ports on this interface. Otherwise, open ports on all interfaces";
    };
  };
  config = mkIf cfg.enable {
    age.secrets = {
      gluster-ca-crt = {
        file = ../../secrets/gluster-ca-crt.age;
        mode = "0644";
      };
      gluster-key = {
        file = ./. + "/../../secrets/gluster-${config.networking.hostName}-key.age";
        mode = "0600";
      };
      gluster-crt = {
        file = ./. + "/../../secrets/gluster-${config.networking.hostName}-crt.age";
        mode = "0644";
      };
    };

    networking.firewall = let
      ports = {
        # https://github.com/gluster/glusterfs/blob/devel/extras/firewalld/glusterfs.xml
        allowedTCPPorts = [
          24007 # glusterd
          24008 # glusterd RDMA port management
          55555 # glustereventsd
        ];
        allowedTCPPortRanges = [
          { from = 38465; to = 38469; } # Gluster NFS service.
          { from = 49152; to = 60999; } # Gluster inter-brick
        ];
      };
    in (if (stringLength cfg.openFirewallOnInterface > 0) then {
      interfaces."${cfg.openFirewallOnInterface}" = ports;
    } else ports);

    services.glusterfs = {
      enable = true;
      useRpcbind = false; # required for NFS
      tlsSettings = {
        caCert     = config.age.secrets.gluster-ca-crt.path;
        tlsKeyPath = config.age.secrets.gluster-key.path;
        tlsPem     = config.age.secrets.gluster-crt.path;
      };
    };

    systemd.services.glusterd = {
      # fixes
      path = with pkgs; [
        libsemanage # semanage: command not found
        policycoreutils # restorecon: command not found
        hostname # hostname: command not found
        samba # smbd: command not found
      ];
      preStart = ''
        echo "option transport.socket.ssl-cert-depth 1" > /var/lib/glusterd/secure-access
      '';
      postStart = ''
        systemctl restart --no-block ${cfg.distributedVolumeMountName}
      '';
      serviceConfig = optionalAttrs cfg.disknode {
        Requires = [ cfg.backendMountName ];
        After = [ cfg.backendMountName ];
      };
    };

    fileSystems = {
      "${cfg.distributedVolumeMountPoint}" = let
        first = builtins.elemAt nodes 0 ;
        rest = lists.drop 1 nodes;
      in {
        device = (if cfg.mountLocalhost then "127.0.0.1" else first.fqdn) + ":/gv0";
        fsType = "glusterfs";
        options = [
          "x-systemd.requires=glusterd.service"
          "x-systemd.after=glusterd.service"
        ]
        # only configure backups for the mount if mounting over the network via other nodes
        # if mounting via the local gluster service, that will be peering with other nodes anyway
        ++ (optional (cfg.mountLocalhost == false) "backup-volfile-servers=${concatMapStringsSep ":" (node: node.fqdn) rest}");
      };
    } // (optionalAttrs cfg.disknode {
      "${cfg.backendMountPoint}" = {
        device = cfg.backendDevice;
      };
    });

    environment.systemPackages = with pkgs; let
      gluster-status = pkgs.writeShellScriptBin "gluster-status" ''
        echo "### volume status"
        ${glusterfs}/bin/gluster volume status
        echo "### peer status"
        ${glusterfs}/bin/gluster peer status
        echo "### volume info"
        ${glusterfs}/bin/gluster volume info
        echo "### volume heal gv0 info summary"
        ${glusterfs}/bin/gluster volume heal gv0 info summary
      '';
    in [
      gluster-status
    ];
  };
}
