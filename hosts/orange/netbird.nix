{ config, lib, pkgs, ... }: with lib; {
  age.secrets.netbird-private-key.file = ./. + "/../../secrets/${config.networking.hostName}-netbird-privatekey.age";

  age-template.files.netbird-secrets = {
    path = "/etc/${config.services.netbird.clients.default.dir.baseName}/config.d/60-secrets.json";
    # owner = config.services.netbird.clients.default.user.name; # only needed when hardened
    # group = config.services.netbird.clients.default.user.group; # only needed when hardened
    vars = {
      privatekey = config.age.secrets.netbird-private-key.path;
    };
    content = ''
      {
        "PrivateKey": "$privatekey"
      }
    '';
  };

  services.netbird.clients.default = {
    port = 51820;
    openFirewall = true;
    interface = "netbird";
    hardened = false; # fails to bring up DNS route
    dns-resolver = {
      address = "127.0.0.1";
      port = 5353;
    };
  };

  # don't delay network-online
  systemd.network.wait-online.ignoredInterfaces = [ config.services.netbird.clients.default.interface ];

  # protect the secrets in the config file
  systemd.services.netbird-default.serviceConfig.StateDirectoryMode = mkForce "0700";

  # fix etc directory permission (only needed when hardened)
  # system.activationScripts.fix-netbird-etc-perms = {
  #   text = ''
  #     chown ${config.services.netbird.clients.default.user.name}:${config.services.netbird.clients.default.user.group} /etc/${config.services.netbird.clients.default.dir.baseName}/config.d
  #   '';
  # };

  # TODO: let netbird set DNS server routes when hardened
  # services.dbus.packages = let
  #   netbird-dbus-policy = pkgs.stdenv.mkDerivation {
  #     name = "netbird-dbus-policy";
  #     phases = [ "installPhase" ];
  #     installPhase = ''
  #       mkdir -p $out/share/dbus-1/system.d
  #       cat > $out/share/dbus-1/system.d/netbird.conf <<EOF
  #       <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
  #       "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
  #       <busconfig>
  #         <policy user="${config.services.netbird.clients.default.user.name}">
  #           <allow own="io.netbird.DNS"/>
  #           <allow send_destination="org.freedesktop.resolve1"/>
  #           <allow send_destination="org.freedesktop.resolve1" send_interface="org.freedesktop.resolve1.Manager"/>
  #           <allow send_destination="org.freedesktop.resolve1" send_interface="org.freedesktop.resolve1.Link"/>
  #         </policy>
  #       </busconfig>
  #       EOF
  #     '';
  #   };
  # in [ netbird-dbus-policy ];
}