{ config, lib, pkgs, ... }: with lib; let
  cfg = config.disk-savers;

  opts = { ... }: {
    options = {
      targetDir = mkOption {
        type = types.path;
        description = "The path to the directory which needs to be saved.";
        example = "/var/lib/foo";
      };
      targetMountName = mkOption {
        type = types.str;
        description = "Must be identical to `targetDir`, but with dashes instead of slashes, except the first slash, just like systemd-escape does.";
        example = "var-lib-foo";
      };
      diskDir = mkOption {
        type = types.path;
        description = "The path to a directory on disk";
        example = "/var/lib/bar";
      };
      diskDirOptions = mkOption {
        type = types.attrs;
        description = "The options passed to tmpfiles for the lowerdir, workdir and upperdir";
        default = {
          user = "root";
          group = "root";
          mode = "0700";
        };
      };
      ramDirOptions = mkOption {
        type = types.listOf types.str;
        description = "The options to apply to the tmpfs";
        default = [ "mode=0700" ];
      };
      syncEvery = mkOption {
        type = types.str;
        description = "The time between executing rsync (see systemd timer)";
        default = "60s";
      };
    };
  };
in {
  options.disk-savers = mkOption {
    type = types.attrsOf (types.submodule opts);
    description = "Saves disk wear by creating an overlay filesystem with tmpfs";
  };

  config = {
    fileSystems = attrsets.concatMapAttrs (name: value: {
      "${value.diskDir}/ramdisk" = {
        fsType = "tmpfs";
        options = value.ramDirOptions;
      };
      "${value.targetDir}" = {
        fsType = "overlay";
        device = "overlay";
        overlay = {
          upperdir =   "${value.diskDir}/ramdisk/upperdir";
          workdir =    "${value.diskDir}/ramdisk/workdir";
          lowerdir = [ "${value.diskDir}/lowerdir" ];
        };
      };
    }) cfg;

    systemd.tmpfiles.settings = attrsets.concatMapAttrs (name: value: {
      "disk-saver-${name}" = {
        "${value.diskDir}/ramdisk/upperdir".d = value.diskDirOptions;
        "${value.diskDir}/ramdisk/workdir".d = value.diskDirOptions;
        "${value.diskDir}/lowerdir".d = value.diskDirOptions;
      };
    }) cfg;

    systemd.services = attrsets.concatMapAttrs (name: value: {
      "disk-saver-${name}" = {
        script = "${pkgs.lib.getExe pkgs.rsync} -ac --delete ${value.targetDir}/ ${value.diskDir}/lowerdir/";
        serviceConfig = {
          Type = "oneshot";
        };
      };
    }) cfg;

    systemd.timers = attrsets.concatMapAttrs (name: value: {
      "disk-saver-${name}" = {
        timerConfig = {
          OnUnitActiveSec = value.syncEvery;
          Unit = "disk-saver-${name}.service";
        };
        # TODO: what does nix use in nixland instead of systemd-escape?
        requires = [ "${value.targetMountName}.mount" ];
        wantedBy = ["multi-user.target"];
      };
    }) cfg;
  };
}