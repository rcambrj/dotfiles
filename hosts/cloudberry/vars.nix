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

    wan-netdev = ifaces.wan; # temporarily
    wan-vlan = 6;

    mgmt-netdev     = "mgmt";
    mgmt-vlan       = 1;
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

    lte-netdev = "lte";
    lte-vlan   = 45;
    lte-prefix = "192.168.44";
    lte-bits   = "24";
    lte-ip     = "${lte-prefix}.3";
    lte-cidr   = "${lte-ip}/${lte-bits}";
    lte-gw     = "${lte-prefix}.1";
  };
}