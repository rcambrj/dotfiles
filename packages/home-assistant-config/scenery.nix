{ lib, ... }: let
  groups = import ./lib/light-groups.nix;
in {
  "configuration.yaml".scenery = {
    lights = [
      {
        entity_id = lib.flatten (map (group: group.light_targets) groups);
        favorite_colors = [
          # { color_temp_kelvin = 2000; } # warmest
          { color_temp_kelvin = 2200; }
          { color_temp_kelvin = 2400; }
          { color_temp_kelvin = 3000; }
          { color_temp_kelvin = 4800; }
          # { color_temp_kelvin = 6535; } # coolest
        ];
      }
    ];
  };
}