{ inputs, config, lib, ... }:
with lib;
let
  # Dell Wyse 3040 (test machine)
  # ifaces' = {
  #   wan        = "enp1s0";    # builtin
  #   vlan-trunk = "enp0s20u1"; # front right usb3
  #   lan-0      = "enp0s20u2"; # front left usb2
  #   lan-1      = "enp0s20u3"; # rear lower usb2
  #   lan-2      = "enp0s20u4"; # rear upper usb2
  # };
  # TOPTON 4-port
  ifaces' = {
    wan        = "enp1s0";
    vlan-trunk = "enp2s0";
    lan-0      = "enp3s0";
    lan-1      = "enp4s0";
  };
  dns-upstreams = [
    "1.1.1.1"
    "8.8.8.8"
    "9.9.9.9"
  ];
  netbird-netdev = config.services.netbird.clients.default.interface;
  netbird-port   = config.services.netbird.clients.default.port;
in {
  imports = [
    inputs.self.nixosModules.router
  ];

  age.secrets = {
    telegram-router-bot-key.file = ../../secrets/telegram-router-bot-key.age;
    telegram-group.file = ../../secrets/telegram-group.age;
  };

  router = rec {
    # this configuration shape is still undocumented. sorry.
    # each router.networks configures:
    # * a CIDR network, where the machine has one address
    # * a single interface or multiple interfaces on a bridge (possibly VLAN'd)
    # it's not currently possible to configure more than one CIDR or IP
    # address per router.networks value
    #
    # the router.networks.mode attribute can be:
    # * dhcp-uplink
    # * pppoe-uplink
    # * static-uplink
    # * dhcp-downlink
    # this attribute conflates a few things (which I want to separate):
    # * uplink or downlink (for firewall rules - what OpenWRT calls "zones")
    # * dhcp / static / pppoe (IP identity acquisition)
    #
    # the router.uplink-failover system only supports 2 uplinks - a primary
    # and secondary, I'd like to improve it to support n uplinks.
    #

    telegram-token-path = config.age.secrets.telegram-router-bot-key.path;
    telegram-group-path = config.age.secrets.telegram-group.path;

    ifaces = ifaces';

    uplink-failover = {
      interval  = "10s";
      rise-n    = "3";
      fall-n    = "3";
      primary   = "wan";
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
      wan = recursiveUpdate rec {
        rt   = 926;
        prio = uplink-failover.rule-prio.primary;
        ping-targets = dns-upstreams;
      } {
        dev-mode = rec {
          ifname = ifaces'.wan;
          ifaces = {
            t = [];
            u = [ ifaces'.wan ];
          };
          mode       = "dhcp-uplink";
          bw-egress  = "1G";
          bw-ingress = "1G";
        };
        kpn-zakelijk = rec {
          ifname = "pppoe-wan";
          ifname-pppoe = "${ifaces'.wan}-${toString vlan}";
          vlan   = 6;
          ifaces = {
            t = [ ifaces'.wan ];
            u = [];
          };
          mode       = "pppoe-uplink";
          bw-egress  = "1G";
          bw-ingress = "1G";
        };
        odido-consument = rec {
          ifname = "${ifaces'.wan}-${toString vlan}";
          vlan   = 300;
          ifaces = {
            t = [ ifaces'.wan ];
            u = [];
          };
          mode       = "dhcp-uplink";
          bw-egress  = "400M";
          bw-ingress = "400M";
        };
      }."odido-consument";

      lte = rec {
        ifname = "${ifaces'.vlan-trunk}-${toString vlan}";
        vlan = 44;
        ifaces = {
          t = [ ifaces'.vlan-trunk ];
          u = [];
        };
        mode        = "static-uplink";
        ip4-prefix  = "192.168.44";
        ip4-subnet  = "24";
        ip4-address = "${ip4-prefix}.3";
        ip4-cidr    = "${ip4-address}/${ip4-subnet}";
        ip4-gateway = "${ip4-prefix}.1";
        rt          = 583;
        prio        = uplink-failover.rule-prio.secondary;
        ct          = "0x02000000";
        bw-egress   = "10M";
        bw-ingress  = "10M";
      };

      ont = rec {
        ifname = ifaces'.wan;
        ifaces = {
          t = [];
          u = [ ifaces'.wan ];
        };
        mode        = "static-uplink";
        ip4-prefix  = "192.168.100";
        ip4-subnet  = "24";
        ip4-address = "${ip4-prefix}.2";
        ip4-cidr    = "${ip4-address}/${ip4-subnet}";
        ip4-gateway = "${ip4-prefix}.1";
        rt          = 668;
        prio        = 65535; # never used
      };

      lan = rec {
        ifname = "br-lan";
        mac  = "42:b9:31:e0:f6:5f";
        vlan = 142;
        ifaces = {
          t = [ ifaces'.vlan-trunk ];
          u = [ ifaces'.lan-0 ifaces'.lan-1 ];
        };
        mode        = "dhcp-downlink";

        ip4-prefix  = "192.168.142";
        ip4-subnet  = "24";
        ip4-address = "${ip4-prefix}.1";
        ip4-cidr    = "${ip4-address}/${ip4-subnet}";

        ip6-prefix  = "fd00:cafe:babe";
        ip6-subnet  = "64";
        ip6-address = "${ip6-prefix}::1";
        ip6-cidr    = "${ip6-address}/${ip6-subnet}";
      };

      mgmt = rec {
        ifname = "br-mgmt";
        mac  = "62:b2:63:47:60:ff";
        vlan = 1;
        ifaces = {
          t = [ ifaces'.vlan-trunk ];
          u = [];
        };
        mode        = "dhcp-downlink";

        ip4-prefix  = "192.168.99";
        ip4-subnet  = "24";
        ip4-address = "${ip4-prefix}.1";
        ip4-cidr    = "${ip4-address}/${ip4-subnet}";

        ip6-prefix  = "fd00:dead:beef";
        ip6-subnet  = "64";
        ip6-address = "${ip6-prefix}::1";
        ip6-cidr    = "${ip6-address}/${ip6-subnet}";
      };

      guest = rec {
        ifname = "br-guest";
        mac  = "f5:0f:cB:b9:bF:e3";
        vlan = 83;
        ifaces = {
          t = [ ifaces'.vlan-trunk ];
          u = [];
        };
        mode        = "dhcp-downlink";

        ip4-prefix  = "192.168.83";
        ip4-subnet  = "24";
        ip4-address = "${ip4-prefix}.1";
        ip4-cidr    = "${ip4-address}/${ip4-subnet}";

        ip6-prefix  = "fd00:f005:ba11";
        ip6-subnet  = "64";
        ip6-address = "${ip6-prefix}::1";
        ip6-cidr    = "${ip6-address}/${ip6-subnet}";
      };
    };

    firewall = {
      input = ''
        meta l4proto { icmp, icmpv6 } accept
        iifname { ${netbird-netdev} } tcp dport 22 accept
        iifname { ${netbird-netdev} } udp dport 53 accept
        iifname { ${networks.lan.ifname}, ${netbird-netdev} } tcp dport 80 accept
        iifname { ${networks.lan.ifname}, ${netbird-netdev} } tcp dport 443 accept
        iifname { ${networks.wan.ifname}, ${networks.lte.ifname} } udp dport ${toString netbird-port} accept
        iifname { ${networks.mgmt.ifname} } udp dport { 3478, 10001 } accept comment "Unifi controller"
        iifname { ${networks.mgmt.ifname} } tcp dport { 8080, 8880, 8843, 6789 } accept comment "Unifi controller"
        iifname { ${netbird-netdev} } ct state { established, related } accept
      '';
      forward = ''
        ip saddr ${client-ips.solar0} drop
        iifname "${networks.lan.ifname}" oifname "${netbird-netdev}" accept
        iifname "${netbird-netdev}"      oifname "${networks.lan.ifname}" accept
      '';
      uplink-failover = {
        forward = '''';
        output = ''
          oifname "${networks.lte.ifname}" ip daddr ${networks.lte.ip4-gateway} accept comment "LTE modem dashboard"
        '';
      };
    };

    dns = {
      domain = "cambridge.me";
      upstreams = dns-upstreams ++ [ "/*.netbird.cloud/127.0.0.62#${toString config.services.netbird.clients.default.dns-resolver.port}" ];
      hosts = {
        "router.cambridge.me" = networks.lan.ip4-address;
        "home.cambridge.me" = client-ips.kubernetes-lb;
      };
      cnames = {
        "cloudberry.cambridge.me" = "router.cambridge.me";
        "orange.cambridge.me" = "orange.netbird.cloud";
      };
    };

    hwaddrs = {
      switch-0     = "60:83:E7:2E:7D:76";
      switch-1     = "28:87:BA:98:89:72";
      ap-top       = "70:a7:41:7f:6d:41";
      ap-gnd       = "70:a7:41:7f:6e:e1";

      br-cranberry = "a6:99:b0:72:64:7e";
      topton-a-1   = "00:e2:69:59:33:76";
      topton-a-2   = "00:e2:69:59:33:77";
      topton-a-3   = "00:e2:69:59:33:78";
      topton-a-4   = "00:e2:69:59:33:79";

      # eventual cloudberry target
      topton-b-1   = "00:e2:69:59:2e:72";
      topton-b-2   = "00:e2:69:59:2e:73";
      topton-b-3   = "00:e2:69:59:2e:74";
      topton-b-4   = "00:e2:69:59:2e:75";

      macmini-2011 = "3C:07:54:49:5D:D6"; # this network card is fried
      dell-wyse-a  = "54:48:10:c2:25:b5";
      dell-wyse-b  = "54:48:10:AB:71:0C";
      aorus-b450   = "B4:2E:99:CB:8E:CB";

      dongle-white = "28:87:ba:25:be:cf";
      dongle-black = "00:e0:4c:68:04:b5";
      dongle-grey  = "TODO";

      sonoff-s20-1 = "DC:4F:22:37:FD:50";
      sonoff-s20-2 = "5C:CF:7F:7F:50:63";
      sonoff-s20-3 = "5C:CF:7F:7F:50:45";
      sonoff-s20-4 = "5C:CF:7F:7F:54:8F";
      sonoff-s20-5 = "DC:4F:22:37:F0:D4";
      sonoff-s20-6 = "68:C6:3A:D5:AF:08";
      sonoff-s20-7 = "EC:FA:BC:13:1F:1F";

      esp8266-a    = "4C:11:AE:10:BE:0E";
      esp8266-b    = "84:F3:EB:FB:53:A5";
      somfy-tahoma = "68:4E:05:C5:DD:BC";
      solar        = "e0:02:02:01:96:06";
    };

    client-ips = {
      switch-0 = "${networks.mgmt.ip4-prefix}.2"; # not assigned by dhcp
      switch-1 = "${networks.mgmt.ip4-prefix}.3"; # not assigned by dhcp
      ap-top   = "${networks.mgmt.ip4-prefix}.5"; # not assigned by dhcp
      ap-gnd   = "${networks.mgmt.ip4-prefix}.6"; # not assigned by dhcp
      # servers
      cranberry  = "${networks.lan.ip4-prefix}.21";
      blueberry  = "${networks.lan.ip4-prefix}.22";
      elderberry = "${networks.lan.ip4-prefix}.23";
      gaming-pc  = "${networks.lan.ip4-prefix}.26";
      # not assigned by dhcp, metallb arps this address into existence
      kubernetes-lb = "${networks.lan.ip4-prefix}.50";

      # switches
      sonoff-s20-1 = "${networks.lan.ip4-prefix}.51";
      sonoff-s20-2 = "${networks.lan.ip4-prefix}.52";
      sonoff-s20-3 = "${networks.lan.ip4-prefix}.53";
      sonoff-s20-4 = "${networks.lan.ip4-prefix}.54";
      sonoff-s20-5 = "${networks.lan.ip4-prefix}.55";
      sonoff-s20-6 = "${networks.lan.ip4-prefix}.56";
      sonoff-s20-7 = "${networks.lan.ip4-prefix}.57";
      # sensors
      ventilator   = "${networks.lan.ip4-prefix}.71";
      dsmr         = "${networks.lan.ip4-prefix}.72";
      somfy-tahoma = "${networks.lan.ip4-prefix}.73";
      solar0       = "${networks.lan.ip4-prefix}.74";
    };

    hosts = [
      # infra
      # { name = "cloudberry";   ip = networks.mgmt.ip4-address; hwaddr = networks.mgmt.mac; }
      { name = "switch-0";     ip = client-ips.switch-0;   hwaddr = hwaddrs.switch-0; }
      { name = "switch-1";     ip = client-ips.switch-1;   hwaddr = hwaddrs.switch-1; }
      { name = "ap-top";       ip = client-ips.ap-top;     hwaddr = hwaddrs.ap-top; }
      { name = "ap-gnd";       ip = client-ips.ap-gnd;     hwaddr = hwaddrs.ap-gnd; }

      # servers
      # { name = "cloudberry";   ip = networks.lan.ip4-address; hwaddr = networks.lan.mac; }
      { name = "cranberry";    ip = client-ips.cranberry;  hwaddr = hwaddrs.br-cranberry; }
      { name = "blueberry";    ip = client-ips.blueberry;  hwaddr = hwaddrs.dongle-white; } # was hwadders.macmini-2011
      { name = "elderberry";   ip = client-ips.elderberry; hwaddr = hwaddrs.dell-wyse-a; }
      { name = "gaming-pc";    ip = client-ips.gaming-pc;  hwaddr = hwaddrs.aorus-b450; }
      # switches
      { name = "sonoff-s20-1"; ip = client-ips.sonoff-s20-1; hwaddr = hwaddrs.sonoff-s20-1; }
      { name = "sonoff-s20-2"; ip = client-ips.sonoff-s20-2; hwaddr = hwaddrs.sonoff-s20-2; }
      { name = "sonoff-s20-3"; ip = client-ips.sonoff-s20-3; hwaddr = hwaddrs.sonoff-s20-3; }
      { name = "sonoff-s20-4"; ip = client-ips.sonoff-s20-4; hwaddr = hwaddrs.sonoff-s20-4; }
      { name = "sonoff-s20-5"; ip = client-ips.sonoff-s20-5; hwaddr = hwaddrs.sonoff-s20-5; }
      { name = "sonoff-s20-6"; ip = client-ips.sonoff-s20-6; hwaddr = hwaddrs.sonoff-s20-6; }
      { name = "sonoff-s20-7"; ip = client-ips.sonoff-s20-7; hwaddr = hwaddrs.sonoff-s20-7; }
      # sensors
      { name = "ventilator";   ip = client-ips.ventilator;   hwaddr = hwaddrs.esp8266-a; }
      { name = "dsmr";         ip = client-ips.dsmr;         hwaddr = hwaddrs.esp8266-b; }
      { name = "somfy-tahoma"; ip = client-ips.somfy-tahoma; hwaddr = hwaddrs.somfy-tahoma; }
      { name = "solar0";       ip = client-ips.solar0;       hwaddr = hwaddrs.solar; }
    ];

    port-forwards = [
      # { proto = "tcp"; ports = [ "443" ]; to = client-ips.kubernetes-lb; }

      # wreckfest
      { proto = "tcp"; ports = [ "27015-27016" "33540" ]; to = client-ips.gaming-pc; }
      { proto = "udp"; ports = [ "27015-27016" "33540" ]; to = client-ips.gaming-pc; }
    ];
  };
}