{ ... }: {
  "home-assistant.yaml".automation = [
    {
      alias = "Mosquitos ON at sunset";
      mode = "single";
      trigger = [{
      platform = "sun";
      event = "sunset";
      offset = 0;
      }];
      action = [{
      action = "switch.turn_on";
      target = {
        entity_id = [
        "switch.mosquito_0"
        "switch.mosquito_1"
        "switch.mosquito_2"
        ];
      };
      }];
    }
    {
      alias = "Mosquitos OFF at sunrise";
      mode = "single";
      trigger = [{
      platform = "sun";
      event = "sunrise";
      offset = 0;
      }];
      action = [{
      action = "switch.turn_off";
      target = {
        entity_id = [
        "switch.mosquito_0"
        "switch.mosquito_1"
        "switch.mosquito_2"
        ];
      };
      }];
    }
  ];
}