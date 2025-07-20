let
  sshKeys = import ./lib/ssh-keys.nix;
  defaults = [ sshKeys.mbp2024 sshKeys.linux-vm sshKeys.mango ];
  kubenodes = [ sshKeys.blueberry sshKeys.cranberry sshKeys.strawberry ];
in {
  "secrets/acme-cloudflare.age".publicKeys = defaults ++ kubenodes ++ [ sshKeys.elderberry ];
  "secrets/ldap-admin-rw-password.age".publicKeys = defaults ++ [ ]; # not used
  "secrets/ldap-admin-ro-password.age".publicKeys = defaults ++ [ sshKeys.cranberry sshKeys.blueberry sshKeys.elderberry ];

  # oauth2 apps
  "secrets/blueberry-oauth2-proxy-client-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/cranberry-oauth2-proxy-client-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry sshKeys.cranberry ];
  "secrets/kubernetes-oauth2-proxy-client-secret.age".publicKeys = defaults ++ kubenodes;
  "secrets/argocd-client-secret.age".publicKeys = defaults ++ kubenodes;

  # kubernetes
  "secrets/k3s-token.age".publicKeys = defaults ++ kubenodes;
  "secrets/argocd-session-key.age".publicKeys = defaults ++ kubenodes;
  "secrets/argocd-ssh-key.age".publicKeys = defaults ++ kubenodes;
  "secrets/kubernetes-oauth2-proxy-cookie-secret.age".publicKeys = defaults ++ kubenodes;
  "secrets/longhorn-backup-b2-apikey.age".publicKeys = defaults ++ kubenodes;
  "secrets/longhorn-backup-b2-secret.age".publicKeys = defaults ++ kubenodes;

  # blueberry
  "secrets/home-assistant.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/authelia-jwt.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/authelia-session.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/authelia-storage.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/webos-dev-mode-curl.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-pgadmin.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/lldap-jwt-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/lldap-cert-key.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/lldap-env.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-oauth2-proxy-cookie-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/grafana-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/influxdb-admin-password.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/influxdb-admin-token.age".publicKeys = defaults ++ [ sshKeys.blueberry ];

  # cranberry
  "secrets/pia-vpn-user.age".publicKeys = defaults ++ kubenodes;
  "secrets/pia-vpn-pass.age".publicKeys = defaults ++ kubenodes;
  "secrets/cranberry-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-oauth2-proxy-cookie-secret.age".publicKeys = defaults ++ [ sshKeys.cranberry ];

  # orange
  "secrets/photoprism-sftp-password.age".publicKeys = defaults ++ [ sshKeys.orange ];
  "secrets/photoprism-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.orange ];
  "secrets/photoprism-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.orange ];
  "secrets/photoprism-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.orange ];
}