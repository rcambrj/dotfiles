{ wan-gateway, ... }:
let
  ifaces' = {
    wan        = "enp1s0";
    vlan-trunk = "enp1s1";
    lan-0      = "enp1s2";
  };
in rec {
  ifaces = ifaces';

  telegram-token-path = "/dev/null";
  telegram-group-path = "/dev/null";

  uplink-failover = {
    primary = "wan";
    secondary = "lte";
    rule-prio = {
      # main    = 32766
      # default = 32767
      override  = 32767 + 1000;
      primary   = 32767 + 1100;
      secondary = 32767 + 1200;
    };
  };

  networks = {
    wan = rec {
      rt   = 926;
      prio = uplink-failover.rule-prio.primary;
      mac  = "00:00:00:00:00:01";
      ifname = "br-wan";
      ifaces = {
        t = [];
        u = [ ifaces'.wan ];
      };
      mode = "dhcp-uplink";
      ping-targets = [ wan-gateway ];
    };
    lte = rec {
      ifname = "br-lte";
      mac  = "00:00:00:00:00:02";
      vlan = 44;
      ifaces = {
        t = [ ifaces'.vlan-trunk ];
        u = [];
      };
      mode        = "static-uplink";
      ip4-prefix  = "10.22.0";
      ip4-subnet  = "24";
      ip4-address = "${ip4-prefix}.2";
      ip4-cidr    = "${ip4-address}/${ip4-subnet}";
      ip4-gateway = "${ip4-prefix}.1";
      rt          = 583;
      prio        = uplink-failover.rule-prio.secondary;
      ct          = "0x02000000";
    };

    lan = rec {
      ifname = "br-lan";
      mac  = "00:00:00:00:00:03";
      vlan = 142;
      ifaces = {
        t = [ ifaces'.vlan-trunk ];
        u = [ ifaces'.lan-0 ];
      };
      mode        = "dhcp-server";

      ip4-prefix  = "10.33.0";
      ip4-subnet  = "24";
      ip4-address = "${ip4-prefix}.1";
      ip4-cidr    = "${ip4-address}/${ip4-subnet}";

      ip6-prefix  = "fd00:cafe:babe";
      ip6-subnet  = "48";
      ip6-address = "${ip4-prefix}::1";
      ip6-cidr    = "${ip4-address}/${ip4-subnet}";
    };

    mgmt = rec {
      ifname = "br-mgmt";
      mac  = "00:00:00:00:00:04";
      vlan = 1;
      ifaces = {
        t = [ ifaces'.vlan-trunk ];
        u = [];
      };
      mode        = "dhcp-server";

      ip4-prefix  = "10.44.0";
      ip4-subnet  = "24";
      ip4-address = "${ip4-prefix}.1";
      ip4-cidr    = "${ip4-address}/${ip4-subnet}";

      ip6-prefix  = "fd00:dead:beef";
      ip6-subnet  = "48";
      ip6-address = "${ip4-prefix}::1";
      ip6-cidr    = "${ip4-address}/${ip4-subnet}";
    };
  };

  firewall = {
    input = ''
      # TODO
    '';
    forward = ''
      # TODO
    '';
  };

  dns = {
    "test.example.com" = "10.0.0.0";
  };

  mac = {
    test-client = "00:00:00:00:00:10";
  };

  client-ips = {
    test-client = "${networks.lan.ip4-prefix}.2";
  };

  hosts = [
    { name = "test-client"; ip = client-ips.test-client; hwaddrs = [ mac.test-client ]; }
  ];

  port-forwards = [
    { proto = "tcp"; ports = [ "8080" ]; to = client-ips.test-client; }
  ];
}