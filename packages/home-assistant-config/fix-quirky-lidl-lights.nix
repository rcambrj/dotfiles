{ ... }: {
  # these lights spontaneously comes on. unsure why. tried swapping the bulbs.
  # turn them off again if the other lights in the group aren't on. yolo.
  # seems to be limited to E14 LIDL LIVARNO bulbs.

  "configuration.yaml".automation = let
    quirky_lights = [
      { entity_id = "light.bathroom_mirror_light"; other_entity_id = "light.bathroom_light"; }
      { entity_id = "light.hallway_2_light"; other_entity_id = "light.hallway_1_light"; }
    ];
  in map (quirky_light: {
    alias = "Fix quirky LIDL light: ${quirky_light.entity_id}";
    mode = "single";
    trigger = {
      platform = "state";
      entity_id = quirky_light.entity_id;
      to = "on";
    };
    action = [
      {
        delay = "00:00:00.1";
      }
      {
        condition = "and";
        conditions = [
          {
            condition = "state";
            entity_id = quirky_light.other_entity_id;
            state = "off";
          }
        ];
      }
      {
        action = "homeassistant.turn_off";
        target = {
          entity_id = quirky_light.entity_id;
        };
      }
    ];
  }) quirky_lights;
}