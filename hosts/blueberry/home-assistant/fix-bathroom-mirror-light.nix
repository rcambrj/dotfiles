{ ... }: {
  # this light spontaneously comes on. unsure why. tried swapping the bulb.
  # turn it off again if the ceiling light isn't on. yolo.

  services.home-assistant.config.automation = [{
    alias = "Fix bathroom mirror light";
    mode = "single";
    trigger = {
      platform = "state";
      entity_id = "light.bathroom_mirror_light";
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
            entity_id = "light.bathroom_light";
            state = "off";
          }
        ];
      }
      {
        action = "homeassistant.turn_off";
        target = {
          entity_id = "light.bathroom_mirror_light";
        };
      }
    ];
  }];
}