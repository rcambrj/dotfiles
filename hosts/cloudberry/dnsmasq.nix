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

      # TODO: configure netbird
      # server = "/*.netbird.cloud/127.0.0.1#5053";

      address = "/home.cambridge.me/${home-prefix}.50";
      cname = "orange.cambridge.me,orange.netbird.cloud";

      dhcp-option = [
        # temporarily disable default route for debugging
        # sudo route -n add -net x.x.x.x/32 y.y.y.y
        "option:router"
      ];
    };
  };
}