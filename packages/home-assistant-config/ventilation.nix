{ ... }: {
  "configuration.yaml".input_boolean = {
    ventilation_auto_speed_enabled = {
      name = "Ventilation Auto Speed";
      # initial = true; # don't set so that the state gets restored across restarts
      icon = "mdi:fan-auto";
    };
  };
  "configuration.yaml".script.on_ventilation_auto_turn_on = { sequence = [
    {
      action = "input_boolean.turn_on";
      entity_id = "input_boolean.ventilation_auto_speed_enabled";
    }
  ]; };
  "configuration.yaml".script.on_ventilation_auto_turn_off = { sequence = [{
    action = "input_boolean.turn_off";
    entity_id = "input_boolean.ventilation_auto_speed_enabled";
  }]; };

  "configuration.yaml".automation = [{
    alias = "Update ventilation speed";
    mode = "single";
    trigger = {
      platform = "time_pattern";
      seconds = "/30";
    };
    condition = {
      condition = "state";
      entity_id = "input_boolean.ventilation_auto_speed_enabled";
      state = "on";
    };
    action = [
      {
        action = "light.turn_on";
        target = {
          entity_id = "light.mechanical_ventilation";
        };
        data.brightness_pct = let
          humidityUpper = 80;
          humidityLower = 65;
          humidityRange = humidityUpper - humidityLower;
          speedUpper = 100;
          speedLower = 30;
          speedRange = speedUpper - speedLower;
        in ''
          {% set humidity = states('sensor.bathroom_environmental_sensor_humidity') | float(0) %}
          {% set speed = (humidity - ${toString humidityLower}) / ${toString humidityRange} * ${toString speedRange} + ${toString speedLower} %}
          {{ max(min(speed, ${toString speedUpper}), ${toString speedLower}) | round(0) }}
        '';
      }
    ];
  }];
}
