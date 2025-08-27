{ config, lib, ... }:
with lib;
with config.router;
let
  mac = {
    switch0      = "60:83:E7:2E:7D:76";
    switch1      = "28:87:BA:98:89:72";
    ap-top       = "70:a7:41:7f:6d:41";
    ap-gnd       = "70:a7:41:7f:6e:e1";

    br-cranberry = "a6:99:b0:72:64:7e";
    topton-a-1   = "00:e2:69:59:33:76";
    topton-a-2   = "00:e2:69:59:33:77";
    topton-a-3   = "00:e2:69:59:33:78";
    topton-a-4   = "00:e2:69:59:33:79";

    # eventual cloudberry target
    topton-b-1 = "00:e2:69:59:2e:72";
    topton-b-2 = "00:e2:69:59:2e:73";
    topton-b-3 = "00:e2:69:59:2e:74";
    topton-b-4 = "00:e2:69:59:2e:75";

    macmini-2011 = "3C:07:54:49:5D:D6";
    dell-wyse-a  = "54:48:10:c2:25:b5";
    dell-wyse-b  = "54:48:10:AB:71:0C";
    aorus-b450   = "B4:2E:99:CB:8E:CB";

    dongle-white = "28:87:ba:25:be:cf";
    dongle-black = "00:e0:4c:68:04:b5";

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

  hosts = [
    # infra
    { name = "ap-top";       ip = client-ips.ap-top;  hwaddrs = [ mac.ap-top ]; }
    { name = "ap-gnd";       ip = client-ips.ap-gnd;  hwaddrs = [ mac.ap-gnd ]; }
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
in {
  services.dnsmasq.settings.dhcp-host = map (host: concatStringsSep "," (flatten [host.hwaddrs host.ip host.name])) hosts;
}