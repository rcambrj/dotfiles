{ config, lib, pkgs, ... }:
with config.router;
with lib;
{
  # SQM QoS for *egress* traffic is configured directly on network interfaces.
  #
  # In order to configure SQM QoS for *ingress*, an IFB netdev is created
  # then the ingress traffic is mirrored on the IFB as egress traffic, then
  # the IFB egress traffic is configured with SQM QoS.
  #
  # https://github.com/tohojo/sqm-scripts
  #
  # systemd-networkd doesn't support redirecting the network interface's ingress
  # to the IFB's egress, so here are the systemd services which do just that.
  #
  # from sqm-scripts:
  # $TC qdisc add dev $IFACE handle ffff: ingress
  # $IP link set dev $DEV up
  # $TC filter add dev $IFACE parent ffff: protocol all prio 10 u32 \
  # match u32 0 0 flowid 1:1 action mirred egress redirect dev $DEV

  systemd.services = let
    perNetworkIFB = fn: concatMapAttrs (networkName: network: optionalAttrs (hasAttrByPath ["bw-ingress"] network) (fn networkName network)) networks;
  in perNetworkIFB (networkName: network: let
    ifb = "sqm-${networkName}";
  in {
    "sqm-ifb-redirect-${networkName}" = {
      after = [ "systemd-networkd.service" ];
      requires = [ "systemd-networkd.service" ];
      bindsTo = [ "systemd-networkd.service" ];
      partOf = [ "systemd-networkd.service" ];
      wantedBy = [ "multi-user.target" ];

      script = ''
        set -x
        # cleanup
        ${pkgs.iproute2}/bin/tc qdisc del dev ${network.ifname} handle ffff: ingress || true
        ${pkgs.iproute2}/bin/tc qdisc del dev ${ifb} root || true
        # setup
        ${pkgs.iproute2}/bin/ip link set dev ${ifb} up
        ${pkgs.iproute2}/bin/tc qdisc add dev ${network.ifname} handle ffff: ingress
        ${pkgs.iproute2}/bin/tc filter add dev ${network.ifname} parent ffff: protocol all prio 10 u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev ${ifb}
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  });
}