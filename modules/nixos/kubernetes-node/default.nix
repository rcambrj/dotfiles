{...}: {
  imports = [
    ./argocd.nix
    ./firewall.nix
    ./k3s.nix
    ./longhorn.nix
    ./secrets.nix
  ];

  age.secrets = {
    acme-cloudflare.file = ../../../secrets/acme-cloudflare.age;
    pia-vpn-user.file = ../../../secrets/pia-vpn-user.age;
    pia-vpn-pass.file = ../../../secrets/pia-vpn-pass.age;
    kubernetes-oauth2-proxy-client-secret.file = ../../../secrets/kubernetes-oauth2-proxy-client-secret.age;
    kubernetes-oauth2-proxy-cookie-secret.file = ../../../secrets/kubernetes-oauth2-proxy-cookie-secret.age;
    k3s-token.file = ../../../secrets/k3s-token.age;
    argocd-session-key.file = ../../../secrets/argocd-session-key.age;
    argocd-client-secret.file = ../../../secrets/argocd-client-secret.age;
    argocd-ssh-key.file = ../../../secrets/argocd-ssh-key.age;
  };
}