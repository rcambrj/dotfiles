{ config, perSystem, pkgs, ... }: let
  originalAbsX = 30;
  originalAbsY = 30;
  # set to 1, because I think actually that the only application with bad
  # scroll sensitivity is firefox. why is scrolling inconsistent anyway?!
  scrollFactor = 1;
in {
  programs.ydotool.enable = true;
  users.users.rcambrj.extraGroups = [ config.programs.ydotool.group "input" ];

  services.udev.extraHwdb = ''
evdev:name:ELAN0676:00 04F3:3195 Touchpad:dmi:*svnLENOVO:*pvrThinkPadT14sGen2i**
  EVDEV_ABS_01=::${builtins.toString (builtins.floor (originalAbsY / scrollFactor))}
  EVDEV_ABS_35=::${builtins.toString (builtins.floor (originalAbsX / scrollFactor))}
  EVDEV_ABS_36=::${builtins.toString (builtins.floor (originalAbsY / scrollFactor))}
  EVDEV_ABS_00=::${builtins.toString (builtins.floor (originalAbsX / scrollFactor))}
  '';
}