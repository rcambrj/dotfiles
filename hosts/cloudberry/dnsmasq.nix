{ config, lib, ... }:
with config.router;
with lib;
{
  imports = [
    ./static-leases.nix
  ];

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
        "8.8.8.8"
        "1.1.1.1"

        "/*.netbird.cloud/127.0.0.62#5053"
      ];

      interface = [
        home-netdev
        mgmt-netdev
      ];
      dhcp-range = [
        "${home-netdev},${home-dhcp-start},${home-dhcp-end}"
        "${mgmt-netdev},${mgmt-dhcp-start},${mgmt-dhcp-end}"
      ];

      domain = "cambridge.me";
      expand-hosts = true;

      address = [
        "/router.cambridge.me/${home-ip}"
        "/home.cambridge.me/${client-ips.kubernetes-lb}"
      ];
      cname = "orange.cambridge.me,orange.netbird.cloud";

      dhcp-option = [
        # to debug: temporarily disable default route
        # "option:router"
      ];
    };
  };
}