{ config, lib, perSystem, pkgs, ... }:
let
  vncPort = 5900;
  xstartup = pkgs.writeShellScriptBin "free-games-claimer-xstartup" ''
    # Firefox menus dont work without a WM
    ${lib.getExe pkgs.dwm} &
  '';

  vncHomeDir = pkgs.runCommandLocal "free-games-claimer-vnc-config" {} ''
    mkdir -p $out/.vnc
    cp ${lib.getExe xstartup} $out/.vnc/xstartup
  '';
in {
  environment.systemPackages = [
    perSystem.self.free-games-claimer
  ];

  users.users.free-games-claimer = {
    uid = 1342;
    group = "free-games-claimer";
    isSystemUser = true;
  };
  users.groups.free-games-claimer = {
    gid = 1342;
  };

  networking.firewall.allowedTCPPorts = [
    vncPort # VNC
  ];

  systemd.services.free-games-claimer-vnc = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ProtectHome = true;
      WorkingDirectory = "/var/lib/free-games-claimer-vnc";
      StateDirectory = "free-games-claimer-vnc";
      StateDirectoryMode = "0750";
      RuntimeDirectory = "free-games-claimer-vnc";
      RuntimeDirectoryMode = "0750";
      User = "free-games-claimer";
      Group = "free-games-claimer";
      Restart = "on-failure";
    };
    script = ''
      cat ${config.age.secrets.free-games-claimer-vnc.path} | ${pkgs.tigervnc}/bin/vncpasswd -f > passwd
      HOME=${vncHomeDir} exec ${pkgs.tigervnc}/bin/Xvnc \
        -rfbport ${toString vncPort} \
        -AlwaysShared \
        -PasswordFile passwd \
        :1342
    '';
  };

}