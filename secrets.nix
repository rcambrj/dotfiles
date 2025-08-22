let
  sshKeys = import ./lib/ssh-keys.nix;
  defaults = [ sshKeys.mbp2024 sshKeys.linux-vm sshKeys.mango ];
  kubenodes = [ sshKeys.blueberry sshKeys.cranberry sshKeys.strawberry ];
  disknodes = [ sshKeys.blueberry sshKeys.cranberry sshKeys.strawberry ];
in {
  # cloudflare
  "secrets/acme-cloudflare.age".publicKeys = defaults ++ kubenodes ++ [ sshKeys.elderberry ];

  # oauth2 apps
  "secrets/kubernetes-oauth2-proxy-cookie-secret.age".publicKeys = defaults ++ kubenodes;
  "secrets/kubernetes-oauth2-proxy-client-secret.age".publicKeys = defaults ++ kubenodes;
  "secrets/argocd-client-secret.age".publicKeys = defaults ++ kubenodes;

  # kubernetes
  "secrets/k3s-token.age".publicKeys = defaults ++ kubenodes;

  # argocd
  "secrets/argocd-session-key.age".publicKeys = defaults ++ kubenodes;
  "secrets/argocd-ssh-key.age".publicKeys = defaults ++ kubenodes;

  # pia vpn
  "secrets/pia-vpn-user.age".publicKeys = defaults ++ kubenodes;
  "secrets/pia-vpn-pass.age".publicKeys = defaults ++ kubenodes;

  # lldap
  "secrets/lldap-key-seed.age".publicKeys = defaults ++ kubenodes;
  "secrets/lldap-jwt-secret.age".publicKeys = defaults ++ kubenodes;
  "secrets/ldap-admin-rw-password.age".publicKeys = defaults ++ [ ]; # not used
  "secrets/ldap-admin-ro-password.age".publicKeys = defaults ++ kubenodes ++ [ sshKeys.elderberry ];

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

  # == machine-specific ==
  # cranberry
  "secrets/cranberry-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.cranberry ];

  # blueberry
  "secrets/blueberry-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/blueberry-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.blueberry ];

  # strawberry
  "secrets/strawberry-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.strawberry ];
  "secrets/strawberry-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.strawberry ];
  "secrets/strawberry-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.strawberry ];

  # orange
  "secrets/orange-netbird-privatekey.age".publicKeys = defaults ++ [ sshKeys.orange ];
}