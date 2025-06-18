{ lib, ... }: let
  groups = import ./light-groups.nix;
in {
  services.home-assistant.config.google_assistant = {
    project_id = "dynamic-dreamers-06ff7";
    service_account = {
      client_email = "!secret google_assistant_client_email";
      private_key = "!secret google_assistant_private_key";
    };
    exposed_domains = [ "scene" ];
    expose_by_default = true;
    entity_config = (builtins.listToAttrs (lib.lists.flatten (
      map (group:
        map (target: {
          name = target;
          value = { expose = true; room = group.name; };
        }) (group.light_targets ++ group.switch_targets)
      ) groups
    ))) // {
        "cover.bedroom_blind" = { expose = true; room = "Bedroom"; };
        "cover.office_blind" = { expose = true; room = "Office"; };
    };
  };
}