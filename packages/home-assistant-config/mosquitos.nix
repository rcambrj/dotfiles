{ ... }: let
  mosquitos = import ./lib/mosquitos.nix;
in {
  "configuration.yaml".automation = [
    {
      id = "mosquitos_on";
      alias = "Mosquitos ON at sunset";
      mode = "single";
      trigger = [{
        platform = "sun";
        event = "sunset";
        offset = "-01:00:00";
      }];
      action = [{
        action = "switch.turn_on";
        target = {
          entity_id = mosquitos;
        };
      }];
    }
    {
      id = "mosquitos_off";
      alias = "Mosquitos OFF at sunrise";
      mode = "single";
      trigger = [{
        platform = "sun";
        event = "sunrise";
        offset = "-02:00:00";
      }];
      action = [{
        action = "switch.turn_off";
        target = {
          entity_id = mosquitos;
        };
      }];
    }
  ];
}