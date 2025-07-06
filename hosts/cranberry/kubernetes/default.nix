{...}: {
  imports = [
    ./kubernetes.nix
    ./argocd.nix
    ./secrets.nix
  ];
}