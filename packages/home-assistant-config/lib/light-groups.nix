let
  buttons = import ./buttons.nix;
in [
  {
    key = "hallway";
    name = "Hallway";
    icon = "mdi:stairs";
    button_devices = [
      buttons.hallway_0
      buttons.hallway_1
      buttons.hallway_2
    ];
    light_targets = [
      "light.hallway_0_light"
      "light.hallway_1_light"
      "light.hallway_2_light"
    ];
    switch_targets = [];
    cover_targets = [];
  }
  {
    key = "kitchen";
    name = "Kitchen";
    icon = "mdi:chef-hat";
    button_devices = [
      buttons.kitchen
    ];
    light_targets = [
      "light.kitchen_light"
    ];
    switch_targets = [];
    cover_targets = [];
  }
  {
    key = "living_room";
    name = "Living Room";
    icon = "mdi:sofa-outline";
    button_devices = [
      buttons.living_room
    ];
    light_targets = [
      "light.living_room_west_light"
      "light.living_room_east_light"
      "light.living_room_west_lamp"
    ];
    switch_targets = [
      "switch.living_room_east_lamp"
    ];
    cover_targets = [];
  }
  {
    key = "office";
    name = "Office";
    icon = "mdi:office-building-outline";
    button_devices = [
      buttons.office
    ];
    light_targets = [
      "light.office_light"
    ];
    switch_targets = [];
    cover_targets = [
      "cover.office_blind"
    ];
  }
  {
    key = "bedroom";
    name = "Bedroom";
    icon = "mdi:bed-king-outline";
    button_devices = [
      buttons.bedroom
    ];
    light_targets = [
      "light.bedroom_light"
    ];
    switch_targets = [
      "switch.bedroom_lamp"
    ];
    cover_targets = [
      "cover.bedroom_blind"
    ];
  }
  {
    key = "guest_room";
    name = "Guest Room";
    icon = "mdi:bed-queen-outline";
    button_devices = [
      buttons.guest_room
    ];
    light_targets = [
      "light.guest_room_light"
    ];
    switch_targets = [];
    cover_targets = [];
  }
  {
    key = "bathroom";
    name = "Bathroom";
    icon = "mdi:bathtub-outline";
    button_devices = [
      buttons.bathroom
    ];
    light_targets = [
      "light.bathroom_light"
      "light.bathroom_mirror_light"
    ];
    switch_targets = [];
    cover_targets = [];
  }
  {
    key = "attic";
    name = "Attic";
    icon = "mdi:home-roof";
    button_devices = [
      buttons.attic
    ];
    light_targets = [
      "light.attic_light"
    ];
    switch_targets = [];
    cover_targets = [];
  }
]