{ lib, ... }: let
  groups = import ./lib/light-groups.nix;
  buttons = import ./lib/buttons.nix;
in {
  "configuration.yaml".group = builtins.listToAttrs (map (group: {
    name = group.key + "_lights";
    value = {
      name = group.name + " Lights";
      entities = group.light_targets ++ group.switch_targets;
    };
  }) groups);

  # Philips Hue Dimmer Switch (4 buttons)
  # button 1: turn_on
  # button 2: dim_up
  # button 3: dim_down
  # button 4: turn_off

  "configuration.yaml".automation = (map (group: {
    alias = "Toggle group " + group.name;
    mode = "single";
    trigger = map (button_device: {
      device_id = button_device;
      domain = "zha";
      platform = "device";
      type = "remote_button_short_press";
      subtype = "turn_on";
    }) group.button_devices;
    action = [
      {
        action = ''{% if is_state('group.${group.key}_lights','off') %}homeassistant.turn_on{% else %}homeassistant.turn_off{% endif %}'';
        target = {
          entity_id = "group." + group.key + "_lights";
        };
      }
    ];
  }) groups)
  ++ [
    {
      alias = "Toggle scene \"in bed\"";
      mode = "single";
      trigger = [
        {
          device_id = buttons.bedroom;
          domain = "zha";
          platform = "device";
          type = "remote_button_short_press";
          subtype = "turn_off";
        }
      ];
      action = [
        {
          action = "scene.turn_on";
          target = {
            entity_id = "scene.in_bed";
          };
        }
      ];
    }
    {
      alias = "Toggle bedroom light";
      mode = "single";
      trigger = [
        {
          device_id = buttons.bedroom;
          domain = "zha";
          platform = "device";
          type = "remote_button_short_press";
          subtype = "dim_up";
        }
      ];
      action = [
        {
          action = "light.toggle";
          target = {
            entity_id = [
              "light.bedroom_light"
            ];
          };
        }
      ];
    }
    {
      alias = "Toggle bedroom lamp";
      mode = "single";
      trigger = [
        {
          device_id = buttons.bedroom;
          domain = "zha";
          platform = "device";
          type = "remote_button_short_press";
          subtype = "dim_down";
        }
      ];
      action = [
        {
          action = "switch.toggle";
          target = {
            entity_id = [
              "switch.bedroom_lamp"
            ];
          };
        }
      ];
    }
  ]
  ++ (lib.map (v: {
    alias = "Dim bathroom ${v.direction}";
    mode = "single";
    trigger = [
      {
        device_id = buttons.bathroom;
        domain = "zha";
        platform = "device";
        type = "remote_button_short_press";
        subtype = "dim_${v.direction}";
      }
    ];
    action = [
      {
        action = "light.turn_on";
        target = {
          entity_id = [
            "light.bathroom_light"
            "light.bathroom_mirror_light"
          ];
        };
        data = v.data;
      }
    ];
  }) [
    { direction = "up";   data = { brightness = builtins.floor (255 * 0.60); color_temp_kelvin = 4800; }; }
    { direction = "down"; data = { brightness = builtins.floor (255 * 0.01); color_temp_kelvin = 2200; }; }
  ]);
}