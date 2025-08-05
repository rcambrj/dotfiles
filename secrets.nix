let
  sshKeys = import ./lib/ssh-keys.nix;
  defaults = [ sshKeys.mbp2024 sshKeys.linux-vm sshKeys.mango ];
  kubenodes = [ sshKeys.blueberry sshKeys.cranberry sshKeys.strawberry ];
  disknodes = [ sshKeys.blueberry sshKeys.cranberry sshKeys.strawberry ];
in {
  "secrets/acme-cloudflare.age".publicKeys = defaults ++ kubenodes ++ [ sshKeys.elderberry ];

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
  "secrets/pia-vpn-user.age".publicKeys = defaults ++ kubenodes;
  "secrets/pia-vpn-pass.age".publicKeys = defaults ++ kubenodes;

  # blueberry
  "secrets/home-assistant.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-pgadmin.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/lldap-env.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-oauth2-proxy-cookie-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/grafana-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/influxdb-admin-password.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/influxdb-admin-token.age".publicKeys = defaults ++ [ sshKeys.blueberry ];

  # lldap
  "secrets/lldap-key-seed.age".publicKeys = defaults ++ kubenodes;
  "secrets/lldap-jwt-secret.age".publicKeys = defaults ++ kubenodes;
  "secrets/ldap-admin-rw-password.age".publicKeys = defaults ++ [ ]; # not used
  "secrets/ldap-admin-ro-password.age".publicKeys = defaults ++ [ sshKeys.cranberry sshKeys.blueberry sshKeys.elderberry ];

  # mailgun
  "secrets/mailgun-smtp-password.age".publicKeys = defaults ++ kubenodes;

  # gluster
  "secrets/gluster-ca-key.age".publicKeys = defaults;
  "secrets/gluster-ca-crt.age".publicKeys = defaults ++ disknodes;
  "secrets/gluster-cranberry-key.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/gluster-cranberry-crt.age".publicKeys = defaults ++ disknodes;
  "secrets/gluster-strawberry-key.age".publicKeys = defaults ++ [ sshKeys.strawberry ];
  "secrets/gluster-strawberry-crt.age".publicKeys = defaults ++ disknodes;
  "secrets/gluster-blueberry-key.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/gluster-blueberry-crt.age".publicKeys = defaults ++ disknodes;

  # google-assistant
  "secrets/google-assistant-client-email.age".publicKeys = defaults ++ kubenodes;
  "secrets/google-assistant-private-key.age".publicKeys = defaults ++ kubenodes;

  # telegram bot
  "secrets/telegram-bot-api-key.age".publicKeys = defaults ++ kubenodes;
  "secrets/telegram-group.age".publicKeys = defaults ++ kubenodes;

  # LG webos
  "secrets/webos-dev-mode-token.age".publicKeys = defaults ++ kubenodes;
}