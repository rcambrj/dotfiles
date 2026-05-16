{ ... }: {
  "configuration.yaml".prometheus = {
    namespace = "";
    requires_auth = false;
    component_config = {
      "sensor.bathroom_environmental_sensor_humidity".override_metric = "home_indoor_humidity";
      "sensor.bathroom_environmental_sensor_temperature".override_metric = "home_indoor_temperature";
      "sensor.outdoor_humidity".override_metric = "home_outdoor_humidity";
      "sensor.outdoor_temperature".override_metric = "home_outdoor_temperature";
      "sensor.ventilation_speed".override_metric = "home_ventilation_speed";
      "sensor.ventilation_auto_enabled".override_metric = "home_ventilation_auto_enabled";
    };
    filter.include_entities = [
      "sensor.bathroom_environmental_sensor_humidity"
      "sensor.bathroom_environmental_sensor_temperature"
      "sensor.outdoor_humidity"
      "sensor.outdoor_temperature"
      "sensor.ventilation_speed"
      "sensor.ventilation_auto_enabled"
    ];
  };

  "configuration.yaml".template = [{
    sensor = [
      {
        name = "Outdoor Humidity";
        unique_id = "outdoor_humidity";
        default_entity_id = "sensor.outdoor_humidity";
        unit_of_measurement = "%";
        state_class = "measurement";
        availability = "{{ state_attr('weather.forecast_home', 'humidity') is number }}";
        state = "{{ state_attr('weather.forecast_home', 'humidity') }}";
      }
      {
        name = "Outdoor Temperature";
        unique_id = "outdoor_temperature";
        default_entity_id = "sensor.outdoor_temperature";
        unit_of_measurement = "°C";
        state_class = "measurement";
        availability = "{{ state_attr('weather.forecast_home', 'temperature') is number }}";
        state = "{{ state_attr('weather.forecast_home', 'temperature') }}";
      }
      {
        name = "Ventilation Speed";
        unique_id = "ventilation_speed";
        default_entity_id = "sensor.ventilation_speed";
        unit_of_measurement = "%";
        state_class = "measurement";
        availability = "{{ is_state('light.mechanical_ventilation', 'off') or state_attr('light.mechanical_ventilation', 'brightness') is number }}";
        state = ''
          {% if is_state('light.mechanical_ventilation', 'off') %}
            0
          {% else %}
            {{ (state_attr('light.mechanical_ventilation', 'brightness') / 255 * 100) | round(0) }}
          {% endif %}
        '';
      }
      {
        name = "Ventilation Auto Enabled";
        unique_id = "ventilation_auto_enabled";
        default_entity_id = "sensor.ventilation_auto_enabled";
        state_class = "measurement";
        state = "{{ 1 if is_state('input_boolean.ventilation_auto_speed_enabled', 'on') else 0 }}";
      }
    ];
  }];
}
