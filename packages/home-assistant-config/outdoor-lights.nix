{ lib, ... }: let
  lightIds = import ./lib/outdoor-lights.nix;

  elevationCurve = [
    { elevation = 0; brightness = 0; }
    { elevation = -1; brightness = 1; }
    { elevation = -2; brightness = 2; }
    { elevation = -3; brightness = 4; }
    { elevation = -4; brightness = 8; }
    { elevation = -5; brightness = 16; }
    { elevation = -6; brightness = 32; }
  ];
  elevationCurveTemplate = "[${lib.concatMapStringsSep ", " (point: "{'elevation': ${toString point.elevation}, 'brightness': ${toString point.brightness}}") elevationCurve}]";

  brightnessTemplate = ''
    {% macro brightness_for_elevation(elevation) -%}
      {% set curve = ${elevationCurveTemplate} %}
      {% if elevation >= curve[0].elevation %}
        {{ curve[0].brightness }}
      {% elif elevation <= curve[-1].elevation %}
        {{ curve[-1].brightness }}
      {% else %}
        {% for i in range(curve | length - 1) %}
          {% set upper = curve[i] %}
          {% set lower = curve[i + 1] %}
          {% if elevation <= upper.elevation and elevation >= lower.elevation %}
            {% set progress = (upper.elevation - elevation) / (upper.elevation - lower.elevation) %}
            {{ (upper.brightness + ((lower.brightness - upper.brightness) * progress)) | round(0) }}
          {% endif %}
        {% endfor %}
      {% endif %}
    {%- endmacro %}
    {{ brightness_for_elevation(state_attr('sun.sun', 'elevation') | float(0)) }}
  '';
in {
  "configuration.yaml".automation = [
    {
      id = "outdoor_lights_on_at_night";
      alias = "Outdoor lights on at night";
      mode = "single";
      trigger = [{
        platform = "time_pattern";
        minutes = "/1";
      }];
      variables = {
        brightness_pct = brightnessTemplate;
      };
      action = [{
        action = "light.turn_on";
        target = {
          entity_id = lightIds;
        };
        data = {
          brightness_pct = "{{ brightness_pct | trim | int }}";
        };
      }];
    }
  ];
}
