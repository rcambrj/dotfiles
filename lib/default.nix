{ ... }: {
  format-klipper = import ./format-klipper.nix;
  ldap-cert = ./ldap.pem;
  ssh-keys = import ./ssh-keys.nix;
  template = import ./template.nix;
}