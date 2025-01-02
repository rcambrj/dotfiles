{ config, perSystem, pkgs, ... }: {
  programs.ydotool.enable = true;
  users.users.rcambrj.extraGroups = [ config.programs.ydotool.group "input" ];
}