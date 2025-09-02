{ config, lib, ... }: with lib; let
  cfg = config.router;
in {
  options.router = mkOption {
    # TODO: make options structure more strict once changes slow down
  };

  config.router = let
    # Dell Wyse 3040 (test machine)
    ifaces' = {
      wan     = "enp1s0";    # builtin
      sw0     = "enp0s20u3"; # rear lower usb2
      lan-0   = "enp0s20u4"; # rear upper usb2
      spare-0 = "enp0s20u2"; # front left usb2
      spare-1 = "enp0s20u1"; # front right usb3
    };
  in rec {
    ifaces = ifaces';

    # main    = 32766
    # default = 32767
    uplink-rule-override = 32767 + 1000;
    uplink-rule-wan      = 32767 + 1100;
    uplink-rule-lte      = 32767 + 1200;

    networks = {
      wan = recursiveUpdate rec {
        rt   = 926;
        prio = uplink-rule-wan;
        mac  = "fe:d7:9c:98:73:d2";
      } {
        dev-mode = rec {
          ifname = "br-wan";
          ifaces = {
            t = [];
            u = [ ifaces'.wan ];
          };
          mode = "dhcp-uplink";
        };
        kpn-zakelijk = rec {
          ifname = "pppoe-wan";
          vlan   = 6;
          ifaces = {
            t = [ ifaces'.wan ];
            u = [];
          };
          mode = "pppoe-uplink";
        };
        odido-consument = rec {
          ifname = "br-wan";
          vlan   = 300;
          ifaces = {
            t = [];
            u = [ ifaces'.wan ];
          };
          mode = "dhcp-uplink";
        };
      }."dev-mode";
      lte = rec {
        ifname = "br-lte";
        mac  = "16:0c:9e:d1:b3:72";
        vlan = 44;
        ifaces = {
          t = [ ifaces'.sw0 ];
          u = [];
        };
        mode   = "static-uplink";
        prefix = "192.168.44";
        bits   = "24";
        ip     = "${prefix}.3";
        cidr   = "${ip}/${bits}";
        gw     = "${prefix}.1";
        rt     = 583;
        prio   = uplink-rule-lte;
        ct     = "0x02000000";
      };
      lan = rec {
        ifname = "br-lan";
        mac  = "42:b9:31:e0:f6:5f";
        vlan = 143;
        ifaces = {
          t = [ ifaces'.sw0 ];
          u = [ ifaces'.lan-0 ];
        };
        mode = "dhcp-server";
        prefix     = "192.168.143";
        bits       = "24";
        ip         = "${prefix}.1";
        cidr       = "${ip}/${bits}";
        dhcp-start = "${prefix}.101";
        dhcp-end   = "${prefix}.254";
      };
      mgmt = rec {
        ifname = "br-mgmt";
        mac  = "62:b2:63:47:60:ff";
        vlan = 99;
        ifaces = {
          t = [ ifaces'.sw0 ];
          u = [];
        };
        mode = "dhcp-server";
        prefix     = "192.168.99";
        bits       = "24";
        ip         = "${prefix}.1";
        cidr       = "${ip}/${bits}";
        dhcp-start = "${prefix}.2";
        dhcp-end   = "${prefix}.254";
      };
    };

    mac = {
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

      macmini-2011 = "3C:07:54:49:5D:D6";
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

      esp8266-a    = "4C:11:AE:10:BE:0E";
      esp8266-b    = "84:F3:EB:FB:53:A5";
      somfy-tahoma = "68:4E:05:C5:DD:BC";
      solar        = "e0:02:02:01:96:06";
    };

    client-ips = {
      switch-0 = "${networks.mgmt.prefix}.2"; # not assigned by dhcp
      switch-1 = "${networks.mgmt.prefix}.3"; # not assigned by dhcp
      ap-top   = "${networks.mgmt.prefix}.5";
      ap-gnd   = "${networks.mgmt.prefix}.6";
      # servers
      cranberry  = "${networks.lan.prefix}.21";
      blueberry  = "${networks.lan.prefix}.22";
      elderberry = "${networks.lan.prefix}.23";
      cloudberry = "${networks.lan.prefix}.34";
      gaming-pc  = "${networks.lan.prefix}.26";
      # not assigned by dhcp, metallb arps this address into existence
      kubernetes-lb = "${networks.lan.prefix}.50";

      # switches
      sonoff-s20-1 = "${networks.lan.prefix}.51";
      sonoff-s20-2 = "${networks.lan.prefix}.52";
      sonoff-s20-3 = "${networks.lan.prefix}.53";
      sonoff-s20-4 = "${networks.lan.prefix}.54";
      sonoff-s20-5 = "${networks.lan.prefix}.55";
      sonoff-s20-6 = "${networks.lan.prefix}.56";
      # sensors
      ventilator   = "${networks.lan.prefix}.71";
      dsmr         = "${networks.lan.prefix}.72";
      somfy-tahoma = "${networks.lan.prefix}.73";
      solar0       = "${networks.lan.prefix}.74";
    };

    hosts = [
      # infra
      { name = "switch-0";     ip = client-ips.switch-0;   hwaddrs = [ mac.switch-0 ]; }
      { name = "switch-1";     ip = client-ips.switch-1;   hwaddrs = [ mac.switch-1 ]; }
      { name = "ap-top";       ip = client-ips.ap-top;     hwaddrs = [ mac.ap-top ]; }
      { name = "ap-gnd";       ip = client-ips.ap-gnd;     hwaddrs = [ mac.ap-gnd ]; }
      # servers
      { name = "cranberry";    ip = client-ips.cranberry;  hwaddrs = [ mac.br-cranberry mac.topton-a-1 mac.topton-a-2 mac.topton-a-3 mac.topton-a-4]; }
      { name = "blueberry";    ip = client-ips.blueberry;  hwaddrs = [ mac.macmini-2011 ]; }
      { name = "elderberry";   ip = client-ips.elderberry; hwaddrs = [ mac.dell-wyse-a ]; }
      { name = "cloudberry";   ip = client-ips.cloudberry; hwaddrs = [ mac.dell-wyse-b ]; }
      { name = "gaming-pc";    ip = client-ips.gaming-pc;  hwaddrs = [ mac.aorus-b450 ]; }
      # switches
      { name = "sonoff-s20-1"; ip = client-ips.sonoff-s20-1; hwaddrs = [ mac.sonoff-s20-1 ]; }
      { name = "sonoff-s20-2"; ip = client-ips.sonoff-s20-2; hwaddrs = [ mac.sonoff-s20-2 ]; }
      { name = "sonoff-s20-3"; ip = client-ips.sonoff-s20-3; hwaddrs = [ mac.sonoff-s20-3 ]; }
      { name = "sonoff-s20-4"; ip = client-ips.sonoff-s20-4; hwaddrs = [ mac.sonoff-s20-4 ]; }
      { name = "sonoff-s20-5"; ip = client-ips.sonoff-s20-5; hwaddrs = [ mac.sonoff-s20-5 ]; }
      { name = "sonoff-s20-6"; ip = client-ips.sonoff-s20-6; hwaddrs = [ mac.sonoff-s20-6 ]; }
      # sensors
      { name = "ventilator";   ip = client-ips.ventilator;   hwaddrs = [ mac.esp8266-a ]; }
      { name = "dsmr";         ip = client-ips.dsmr;         hwaddrs = [ mac.esp8266-b ]; }
      { name = "somfy-tahoma"; ip = client-ips.somfy-tahoma; hwaddrs = [ mac.somfy-tahoma ]; }
      { name = "solar0";       ip = client-ips.solar0;       hwaddrs = [ mac.solar ]; }
    ];

    port-forwards = [
      { proto = "tcp"; ports = [ "443" ]; to = client-ips.kubernetes-lb; }

      # wreckfest
      { proto = "tcp"; ports = [ "27015-27016" "33540" ]; to = client-ips.gaming-pc; }
      { proto = "udp"; ports = [ "27015-27016" "33540" ]; to = client-ips.gaming-pc; }
    ];
  };
}