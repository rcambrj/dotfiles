{ ... }: let
  groups = import ./lib/light-groups.nix;
  mosquitos = import ./lib/mosquitos.nix;
in {
  "ui-lovelace.yaml" = {
    # show defaults. use this to temporarily see the shape of new integrations
    # strategy = {
    #   type = "original-states";
    # };

    # or define the dashboard shape
    title = "Overview";
    views = [
      {
        title = "Lights";
        cards = [
          {
            type = "entities";
            title = "Scenes";
            icon = "mdi:image-filter-hdr-outline";
            entities = [
              "scene.in_bed"
              "scene.goodnight"
            ];
          }
        ]
        ++ (builtins.map (group: {
          type = "entities";
          title = group.name;
          icon = group.icon;
          entities = group.light_targets ++ group.switch_targets ++ group.cover_targets;
          show_header_toggle = false; # can't enable due to mixed types
        }) groups)
        ++ [
          {
            type = "entities";
            title = "Mosquitos";
            icon = "mdi:skull-crossbones-outline";
            show_header_toggle = true;
            entities = mosquitos;
          }
          {
            type = "entities";
            title = "Ventilation";
            icon = "mdi:fan";
            show_header_toggle = false;
            entities = [
              "input_boolean.ventilation_auto_speed_enabled"
              "light.mechanical_ventilation"
              "sensor.bathroom_environmental_sensor_humidity"
            ];
          }
          {
            type = "entities";
            title = "3D Printer";
            icon = "mdi:printer-3d-nozzle-outline";
            show_header_toggle = false;
            entities = [
              "switch.3d_printer"
            ];
          }
        ];
      }
    ];
  };
}