{ pkgs, ... }:
let
  xpath = [{
    fields = {
      state    = "string(real_time_data/state)";
      Vac_l1   = "number(real_time_data/Vac_l1)";
      Vac_l2   = "number(real_time_data/Vac_l2)";
      Vac_l3   = "number(real_time_data/Vac_l3)";
      Iac_l1   = "number(real_time_data/Iac_l1)";
      Iac_l2   = "number(real_time_data/Iac_l2)";
      Iac_l3   = "number(real_time_data/Iac_l3)";
      Freq1    = "number(real_time_data/Freq1)";
      Freq2    = "number(real_time_data/Freq2)";
      Freq3    = "number(real_time_data/Freq3)";
      pac1     = "number(real_time_data/pac1)";
      pac2     = "number(real_time_data/pac2)";
      pac3     = "number(real_time_data/pac3)";
      p-ac     = "number(real_time_data/p-ac)";
      temp     = "number(real_time_data/temp)";
      e-today  = "number(real_time_data/e-today)";
      t-today  = "number(real_time_data/t-today)";
      e-total  = "number(real_time_data/e-total)";
      CO2      = "number(real_time_data/CO2)";
      t-total  = "number(real_time_data/t-total)";
      v-pv1    = "number(real_time_data/v-pv1)";
      v-pv2    = "number(real_time_data/v-pv2)";
      v-pv3    = "number(real_time_data/v-pv3)";
      v-bus    = "number(real_time_data/v-bus)";
      maxPower = "number(real_time_data/maxPower)";
      i-pv11   = "number(real_time_data/i-pv11)";
      i-pv12   = "number(real_time_data/i-pv12)";
      i-pv13   = "number(real_time_data/i-pv13)";
      i-pv14   = "number(real_time_data/i-pv14)";
      i-pv21   = "number(real_time_data/i-pv21)";
      i-pv22   = "number(real_time_data/i-pv22)";
      i-pv23   = "number(real_time_data/i-pv23)";
      i-pv24   = "number(real_time_data/i-pv24)";
      i-pv31   = "number(real_time_data/i-pv31)";
      i-pv32   = "number(real_time_data/i-pv32)";
      i-pv33   = "number(real_time_data/i-pv33)";
      i-pv34   = "number(real_time_data/i-pv34)";
    };
  }];
in (pkgs.formats.toml {}).generate "foo.toml" {
  inputs = {
    # for development while the solar inverter is off
    file = {
      inherit xpath;
      data_format = "xml";
      files = ["/var/lib/solar.xml"];
    };
    # http = {
    #   inherit xpath;
    #   data_format = "xml";
    #   urls = [ "https://solar0.cambridge.me/real_time_data.xml" ];
    #   timeout = "3s";
    # };
  };
  outputs = {
    prometheus_client = {
      listen = ":9126";
      path = "/metrics";
      collectors_exclude = ["gocollector" "process"];
    };
  };
}