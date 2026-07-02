{ lib, ... }: let
  lightIds = [
    "light.garden_west_light"
  ];

  rampDurationMinutes = 30;
  curve = [ 0 1 5 10 30 70 100 ];

  stepDelaySeconds = rampDurationMinutes * 60 / ((builtins.length curve) - 1);
  stepDelay = "00:0${toString (stepDelaySeconds / 60)}:00";

  stepAction = percent: {
    action = "light.turn_on";
    target = {
      entity_id = lightIds;
    };
    data = {
      brightness_pct = percent;
    };
  };
  rampActions = curve: lib.lists.flatten (lib.imap0 (i: percent:
    lib.optional (i > 0) { delay = stepDelay; } ++ [ (stepAction percent) ]
  ) curve);
in {
  "configuration.yaml".automation = [
    {
      id = "outdoor_lights_on_at_sunset";
      alias = "Outdoor lights ON at sunset";
      mode = "restart";
      trigger = [{
        platform = "sun";
        event = "sunset";
      }];
      action = rampActions curve;
    }
    {
      id = "outdoor_lights_off_at_sunrise";
      alias = "Outdoor lights OFF at sunrise";
      mode = "restart";
      trigger = [{
        platform = "sun";
        event = "sunrise";
        offset = "-00:${toString rampDurationMinutes}:00";
      }];
      action = rampActions (lib.lists.drop 1 (lib.lists.reverseList curve));
    }
  ];
}
