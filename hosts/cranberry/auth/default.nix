{ ... }: {
  imports = [
    ./oauth2-proxy.nix
    ./ldap-cert.nix
  ];
}