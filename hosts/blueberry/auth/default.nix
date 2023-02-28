{ ... }: {
  imports = [
    ./lldap.nix
    ./dex.nix
    ./oauth2-proxy.nix
  ];
}