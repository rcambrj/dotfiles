{ config, lib, pkgs, ... }:
with config.router;
with lib;
let
  dhcpNetworks = filterAttrs (networkName: network: network.mode == "dhcp-server") networks;
in {
  options = {};
  config = {
    services.resolved.enable = false;
    services.dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        domain-needed = true;
        bogus-priv = true;
        no-resolv = true;
        no-hosts = true;
        dhcp-authoritative = true;
        localise-queries = true;
        stop-dns-rebind = true;
        rebind-localhost-ok = true;

        server = [
          # RFC6761 domains that should not be forwarded to Internet name servers, asking questions that they won't know the answer to.
          "/bind/"
          "/invalid/"
          "/local/"
          "/localhost/"
          "/onion/"
          "/test/"

          "9.9.9.9"
          "1.1.1.1"
          "8.8.8.8"

          "/*.netbird.cloud/127.0.0.62#5053"
        ];
        domain = "cambridge.me";
        expand-hosts = true;
        address = mapAttrsToList (host: ip: "/${host}/${ip}") dns;
        cname = "orange.cambridge.me,orange.netbird.cloud";

        # resolve the static DHCP hosts
        host-record = map (host: concatStringsSep "," [ host.name "${host.name}.cambridge.me" host.ip ]) hosts;
      };
    };
  };
}