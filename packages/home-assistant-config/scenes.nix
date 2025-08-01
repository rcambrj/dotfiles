{ ... }: {
  "configuration.yaml".scene = [
    # hass doesnt support groups in scenes, only entities
    # TODO: workaround with groups from light-groups.nix
    {
      name = "in bed";
      entities = {
        "switch.bedroom_lamp" = "on";
        "light.bedroom_light" = "off";
        "cover.bedroom_blind" = {
          state = "open";
          current_position = 8;
        };
      };
    }
    {
      name = "goodnight";
      entities = {
        "switch.bedroom_lamp" = "off";
        "light.bedroom_light" = "off";
        "cover.bedroom_blind" = {
          state = "open";
          current_position = 8;
        };
        # rest off
        "light.hallway_0_light" = "off";
        "light.hallway_1_light" = "off";
        "light.hallway_2_light" = "off";
        "light.living_room_west_light" = "off";
        "light.living_room_east_light" = "off";
        "light.living_room_west_lamp" = "off";
        "switch.living_room_east_lamp" = "off";
        "light.kitchen_light" = "off";
        "light.bathroom_light" = "off";
        "light.bathroom_mirror_light" = "off";
        "light.office_light" = "off";
        # "light.guest_room_light" = "off";
        "light.attic_light" = "off";
      };
    }
    {
      name = "movie";
      entities = {
        "light.living_room_west_light" = "off";
        "light.living_room_east_light" = "off";
        "light.living_room_west_lamp" = "on";
        "switch.living_room_east_lamp" = "on";
        "light.kitchen_light" = "off";
      };
    }
  ];
}