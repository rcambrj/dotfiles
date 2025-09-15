{ primary-gateway, client1-hwaddr, ... }:
let
  ifaces' = {
    primary    = "enp1s0";
    vlan-trunk = "enp1s1";
    lan-0      = "enp1s2";
  };
in rec {
  ifaces = ifaces';

  telegram-token-path = "/dev/null";
  telegram-group-path = "/dev/null";

  uplink-failover = {
    interval  = "1s";
    rise-n    = "2";
    fall-n    = "2";
    primary   = "primary";
    secondary = "secondary";
    rule-prio = {
      # main    = 32766
      # default = 32767
      override  = 32767 + 1000;
      primary   = 32767 + 1100;
      secondary = 32767 + 1200;
    };
  };

  networks = {
    primary = rec {
      rt   = 926;
      prio = uplink-failover.rule-prio.primary;
      mac  = "00:00:00:00:00:01";
      ifname = "br-primary";
      ifaces = {
        t = [];
        u = [ ifaces'.primary ];
      };
      mode = "dhcp-uplink";
      ping-targets = [ primary-gateway ];
    };
    secondary = rec {
      ifname = "br-secondary";
      mac  = "00:00:00:00:00:02";
      vlan = 3;
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

    lan-0 = rec {
      ifname = "br-lan-0";
      mac  = "00:00:00:00:00:03";
      vlan = 2;
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
      ip6-address = "${ip6-prefix}::1";
      ip6-cidr    = "${ip6-address}/${ip6-subnet}";
    };

    lan-1 = rec {
      ifname = "br-lan-1";
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
      ip6-address = "${ip6-prefix}::1";
      ip6-cidr    = "${ip6-address}/${ip6-subnet}";
    };
  };

  firewall = {
    input = ''
      # TODO
    '';
    forward = ''
      # TODO
    '';
    uplink-failover = {
      forward = '''';
      output = ''
        oifname "${networks.secondary.ifname}" ip daddr ${networks.secondary.ip4-gateway} accept comment "secondary modem dashboard"
      '';
    };
  };

  dns = {
    "test.example.com" = "10.0.0.0";
  };

  mac = {
    client1 = client1-hwaddr;
  };

  client-ips = {
    client1 = "${networks.lan-0.ip4-prefix}.11";
  };

  hosts = [
    { name = "client1"; ip = client-ips.client1; hwaddr = mac.client1; }
  ];

  port-forwards = [
    { proto = "tcp"; ports = [ "8080" ]; to = client-ips.client1; }
  ];
}