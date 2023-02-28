{ config, lib, ... }:
let
  xpath = [{
    fields = {
      # DC Input Phase 1
      v-pv1    = "number(real_time_data/v-pv1)";
      i-pv11   = "number(real_time_data/i-pv11)";
      i-pv12   = "number(real_time_data/i-pv12)";
      i-pv13   = "number(real_time_data/i-pv13)";
      i-pv14   = "number(real_time_data/i-pv14)";
      # DC Input Phase 2
      v-pv2    = "number(real_time_data/v-pv2)";
      i-pv21   = "number(real_time_data/i-pv21)";
      i-pv22   = "number(real_time_data/i-pv22)";
      i-pv23   = "number(real_time_data/i-pv23)";
      i-pv24   = "number(real_time_data/i-pv24)";
      # DC Input Phase 3
      v-pv3    = "number(real_time_data/v-pv3)";
      i-pv31   = "number(real_time_data/i-pv31)";
      i-pv32   = "number(real_time_data/i-pv32)";
      i-pv33   = "number(real_time_data/i-pv33)";
      i-pv34   = "number(real_time_data/i-pv34)";

      # AC Output Phase 1
      Vac_l1   = "number(real_time_data/Vac_l1)"; # Grid Voltage
      Iac_l1   = "number(real_time_data/Iac_l1)"; # Grid Current
      pac1     = "number(real_time_data/pac1)"; # Grid Power
      Freq1    = "number(real_time_data/Freq1)"; # Grid Frequency
      # AC Output Phase 2
      Vac_l2   = "number(real_time_data/Vac_l2)";
      Iac_l2   = "number(real_time_data/Iac_l2)";
      pac2     = "number(real_time_data/pac2)";
      Freq2    = "number(real_time_data/Freq2)";
      # AC Output Phase 3
      Vac_l3   = "number(real_time_data/Vac_l3)";
      Iac_l3   = "number(real_time_data/Iac_l3)";
      pac3     = "number(real_time_data/pac3)";
      Freq3    = "number(real_time_data/Freq3)";

      # Statistics
      p-ac     = "number(real_time_data/p-ac)"; # Grid Total Power
      e-today  = "number(real_time_data/e-today)"; # Today Energy
      e-total  = "number(real_time_data/e-total)"; # Total Energy
      t-today  = "number(real_time_data/t-today)"; # Today Running Time
      t-total  = "number(real_time_data/t-total)"; # Total Running Time

      state    = "string(real_time_data/state)"; # Inverter State
      temp     = "number(real_time_data/temp)"; # Inverter Temperature
      v-bus    = "number(real_time_data/v-bus)"; # Bus Voltage
      CO2      = "number(real_time_data/CO2)"; # CO2 Emission Reduction
      maxPower = "number(real_time_data/maxPower)"; # Today Max Power
    };
  }];
in {
  template.files.telegraf-env = {
    vars = {
      influxdb_token = config.age.secrets.influxdb-admin-token.path;
    };
    content = ''
      INFLUXDB_TOKEN=$influxdb_token
    '';
  };


  services.telegraf = {
    enable = true;
    extraConfig = {
      agent = {
        omit_hostname = true;
      };
      inputs = {
        # for development while the solar inverter is off
        # file = [{
        #   inherit xpath;
        #   name_override = "solar";
        #   data_format = "xml";
        #   interval = "30s";
        #   files = ["/var/lib/solar.xml"];
        #   tags = {
        #     bucket = "energy";
        #   };
        # }];
        http = [{
          inherit xpath;
          name_override = "solar";
          data_format = "xml";
          interval = "5m";
          tagexclude = ["url"];
          urls = [ "http://solar0.cambridge.me/real_time_data.xml" ];
          timeout = "3s";
          tags = {
            bucket = "energy";
          };
        }];
        prometheus = [{
          name_override = "dsmr";
          interval = "5m";
          tagexclude = ["url"];
          urls = [ "http://dsmr.cambridge.me/metrics" ];
          timeout = "3s";
          tags = {
            bucket = "energy";
          };
        }];
      };
      outputs = {
        # prometheus_client = [{
        #   listen = ":9126";
        #   path = "/metrics";
        #   expiration_interval = "5m";
        #   string_as_label = false;
        #   collectors_exclude = ["gocollector" "process"];
        # }];
        influxdb_v2 = [{
          urls = [ "http://localhost:8086" ];
          token = "$INFLUXDB_TOKEN";
          organization = "main";
          bucket_tag = "bucket";
          exclude_bucket_tag = true;
        }];
      };
    };
    environmentFiles = [config.template.files.telegraf-env.path];
  };
}