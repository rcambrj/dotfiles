{ ... }: {
  format-klipper = import ./format-klipper.nix;
  ssh-keys = import ./ssh-keys.nix;
  template = import ./template.nix;
}