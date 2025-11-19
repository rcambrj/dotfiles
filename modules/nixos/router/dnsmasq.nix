{ config, lib, pkgs, ... }:
with config.router;
with lib;
{
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
          "/netbird/"
        ] ++ dns.upstreams;
        domain = dns.domain;
        expand-hosts = true;
        address = mapAttrsToList (host: ip: "/${host}/${ip}") (dns.hosts or {});
        cname = mapAttrsToList (host: target: "${host},${target}") (dns.cnames or {});

        # resolve the static DHCP hosts
        host-record = map (host: concatStringsSep "," [ host.name "${host.name}.${dns.domain}" host.ip ]) hosts;
      };
    };
  };
}