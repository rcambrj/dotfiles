{ config, lib, ... }: with lib; let
  cfg = config.router;
in {
  # TOPTON MAC addresses
  # 00:e2:69:59:2e:72
  # 00:e2:69:59:2e:73
  # 00:e2:69:59:2e:74
  # 00:e2:69:59:2e:75

  options.router = mkOption {
    # TODO: make options structure more strict once changes slow down
  };

  config.router = rec {
    # Dell Wyse 3040 (test machine)
    ifaces = {
      wan    = "enp1s0";     # builtin
      sw0    = "enp0s20u3";  # rear lower usb2
      home-0 = "enp0s20u4";  # rear upper usb2
      spare-0 = "enp0s20u2"; # front left usb2
      spare-1 = "enp0s20u1"; # front right usb3
    };

    # main    = 32766
    # default = 32767
    uplink-rule-override = 32767 + 1000;
    uplink-rule-wan      = 32767 + 1100;
    uplink-rule-lte      = 32767 + 1200;

    wan-dev-mode     = true;
    wan-vlan         = 6;
    wan-vlan-netdev  = "wan-vlan";
    wan-pppoe-netdev = "wan";
    wan-netdev       = if wan-dev-mode then ifaces.wan else wan-pppoe-netdev;
    wan-rt           = 926;

    lte-netdev = "lte";
    lte-vlan   = 44;
    lte-prefix = "192.168.44";
    lte-bits   = "24";
    lte-ip     = "${lte-prefix}.3";
    lte-cidr   = "${lte-ip}/${lte-bits}";
    lte-gw     = "${lte-prefix}.1";
    lte-rt     = 1583;
    lte-ct     = "0x02000000";

    mgmt-netdev     = "mgmt";
    mgmt-vlan       = 99;
    mgmt-prefix     = "192.168.99";
    mgmt-bits       = "24";
    mgmt-ip         = "${mgmt-prefix}.1";
    mgmt-cidr       = "${mgmt-ip}/${home-bits}";
    mgmt-dhcp-start = "${mgmt-prefix}.2";
    mgmt-dhcp-end   = "${mgmt-prefix}.254";

    home-netdev     = "home";
    home-vlan       = 143;
    home-prefix     = "192.168.143";
    home-bits       = "24";
    home-ip         = "${home-prefix}.1";
    home-cidr       = "${home-ip}/${home-bits}";
    home-dhcp-start = "${home-prefix}.101";
    home-dhcp-end   = "${home-prefix}.254";

    client-ips = {
      switch-0 = "${mgmt-prefix}.2"; # not assigned by dhcp
      switch-1 = "${mgmt-prefix}.3"; # not assigned by dhcp
      ap-top   = "${mgmt-prefix}.5";
      ap-gnd   = "${mgmt-prefix}.6";
      # servers
      cranberry  = "${home-prefix}.21";
      blueberry  = "${home-prefix}.22";
      elderberry = "${home-prefix}.23";
      cloudberry = "${home-prefix}.34";
      gaming-pc  = "${home-prefix}.26";
      # not assigned by dhcp, metallb arps this address into existence
      kubernetes-lb = "${home-prefix}.50";

      # switches
      sonoff-s20-1 = "${home-prefix}.51";
      sonoff-s20-2 = "${home-prefix}.52";
      sonoff-s20-3 = "${home-prefix}.53";
      sonoff-s20-4 = "${home-prefix}.54";
      sonoff-s20-5 = "${home-prefix}.55";
      sonoff-s20-6 = "${home-prefix}.56";
      # sensors
      ventilator   = "${home-prefix}.71";
      dsmr         = "${home-prefix}.72";
      somfy-tahoma = "${home-prefix}.73";
      solar0       = "${home-prefix}.74";
    };
  };
}