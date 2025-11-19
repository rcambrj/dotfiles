{ config, lib, perSystem, pkgs, ... }: with lib; {
  # configure PrivateKey first https://wg.orz.tools/ then
  # netbird up --setup-key=<setup key>
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

  # netbird is broken as of https://github.com/NixOS/nixpkgs/pull/453040
  # but it only impacts netbird.io (hosted).
  # read more https://github.com/rcambrj/netbird-repro
  # I've switched to selfhosted, which is unaffected
  # services.netbird.package = perSystem.nixpkgs-netbird.netbird;

  services.netbird.clients.default = {
    # default wireguard port 51820 for k3s flannel-wg
    port = 51821;
    openFirewall = true;
    interface = "netbird";
    hardened = false; # fails to bring up DNS route
    dns-resolver = {
      address = "127.0.0.62";
      port = mkDefault 53; # systemd-resolved only likes 53, errors otherwise

      # also set:
      # services.resolved.extraConfig = ''
      #   DNS=1.1.1.1#cloudflare-dns.com 8.8.8.8#dns.google 1.0.0.1#cloudflare-dns.com 8.8.4.4#dns.google 2606:4700:4700::1111#cloudflare-dns.com 2001:4860:4860::8888#dns.google 2606:4700:4700::1001#cloudflare-dns.com 2001:4860:4860::8844#dns.google
      #   [Resolve]
      #   DNS=127.0.0.62
      #   Domains=~cambridge.me ~cambridge.netbird
      # '';
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
  # currently fails with:
  # failed to apply DNS host manager update: set interface DNS server calling command with context, err: Permission denied
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