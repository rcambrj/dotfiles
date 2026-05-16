{ ... }: {
  "configuration.yaml".prometheus = {
    requires_auth = false;
    filter.include_entities = [
      "sensor.bathroom_environmental_sensor_humidity"
      "sensor.bathroom_environmental_sensor_temperature"
      "sensor.outdoor_humidity"
      "sensor.outdoor_temperature"
      "sensor.ventilation_speed"
      "input_boolean.ventilation_auto_speed_enabled"
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
        state_class = "measurement";
        availability = "{{ is_state('light.mechanical_ventilation', 'off') or state_attr('light.mechanical_ventilation', 'brightness') is number }}";
        state = ''
          {% if is_state('light.mechanical_ventilation', 'off') %}
            0
          {% else %}
            {{ state_attr('light.mechanical_ventilation', 'brightness') }}
          {% endif %}
        '';
      }
    ];
  }];
}
