{ ... }: {
  "home-assistant.yaml".input_boolean = {
    ventilation_auto_speed_enabled = {
      name = "Ventilation Auto Speed";
      # initial = true; # don't set so that the state gets restored across restarts
      icon = "mdi:fan-auto";
    };
  };
  "home-assistant.yaml".script.on_ventilation_auto_turn_on = { sequence = [
    {
      action = "input_boolean.turn_on";
      entity_id = "input_boolean.ventilation_auto_speed_enabled";
    }
  ]; };
  "home-assistant.yaml".script.on_ventilation_auto_turn_off = { sequence = [{
    action = "input_boolean.turn_off";
    entity_id = "input_boolean.ventilation_auto_speed_enabled";
  }]; };

  "home-assistant.yaml".automation = [{
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
        # const humidity = msg.payload;
        # const humidityLower = 65;
        # const humidityRange = 80 - humidityLower;
        # const speedLower = 30;
        # const speedRange = 100 - speedLower;
        # const speed = Math.max(speedLower, (
        #           humidity - humidityLower
        #     ) / humidityRange * speedRange + speedLower);
        # TODO: how to make this more maintainable?
        data = ''{"brightness_pct":"{{ max(min((states.sensor.bathroom_environmental_sensor_humidity.state|float(0) - 65) / (80 - 65) * 100 + 30, 100), 30) }}"}'';
      }
    ];
  }];
}