{ config, lib, ... }:
with config.router;
with lib;
{
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

      interface = [
        networks.lan.ifname
        networks.mgmt.ifname
      ];
      dhcp-range = [
        "${networks.lan.ifname},${networks.lan.dhcp-start},${networks.lan.dhcp-end}"
        "${networks.mgmt.ifname},${networks.mgmt.dhcp-start},${networks.mgmt.dhcp-end}"
      ];

      domain = "cambridge.me";
      expand-hosts = true;

      address = [
        "/router.cambridge.me/${networks.lan.ip}"
        "/home.cambridge.me/${client-ips.kubernetes-lb}"
      ];
      cname = "orange.cambridge.me,orange.netbird.cloud";

      dhcp-option = [
        # to debug: temporarily disable default route
        # "option:router"
      ];

      dhcp-host = map (host: concatStringsSep "," (flatten [host.hwaddrs host.ip host.name])) hosts;
    };
  };
}