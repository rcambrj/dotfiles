{ ... }: let
  groups = import ./light-groups.nix;
in {
  services.home-assistant.config.group = builtins.listToAttrs (map (group: {
    name = group.key + "_lights";
    value = {
      name = group.name + " Lights";
      entities = group.light_targets ++ group.switch_targets;
    };
  }) groups);

  services.home-assistant.config.automation = map (group: {
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
  }) groups;
}