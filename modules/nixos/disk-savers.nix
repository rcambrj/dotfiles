{ config, lib, pkgs, ... }: with lib; let
  cfg = config.disk-savers;

  opts = { ... }: {
    options = {
      targetDir = mkOption {
        type = types.path;
        description = "The path to the directory which needs to be saved.";
      };
      diskDir = mkOption {
        type = types.path;
        description = "The path to a directory on disk";
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
      syncEverySecs = mkOption {
        type = types.int;
        description = "The number of seconds between executing rsync";
        default = 60;
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
        script = "${pkgs.lib.getExe pkgs.rsync} -a --delete ${value.targetDir}/ ${value.diskDir}/lowerdir/";
      };
    }) cfg;

    systemd.timers = attrsets.concatMapAttrs (name: value: {
      "disk-saver-${name}" = {
        timerConfig = {
          OnActiveSec = 60;
          Unit = "disk-saver-${name}.service";
        };
        # TODO: transform value.targetDir to hyphenated
        # requires = [ "var-lib-whatever.mount" ];
        wantedBy = ["multi-user.target"];
      };
    }) cfg;
  };
}