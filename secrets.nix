let
  sshKeys = import ./lib/ssh-keys.nix;
  defaults = [ sshKeys.mbp2024 sshKeys.linux-vm sshKeys.mango ];
  kubenodes = [ sshKeys.blueberry sshKeys.cranberry sshKeys.orange ];
  disknodes = [ sshKeys.blueberry sshKeys.cranberry sshKeys.orange ];
in {
  # cloudflare
  "secrets/cloudflare-token.age".publicKeys = defaults ++ kubenodes ++ [ sshKeys.cloudberry sshKeys.elderberry sshKeys.orange sshKeys.lemon ];
  "secrets/cloudflare-zone-id.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];
  "secrets/cloudflare-ddns-host.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];
  "secrets/cloudflare-tunnel.age".publicKeys = defaults ++ kubenodes;

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
  "secrets/gluster-orange-key.age".publicKeys = defaults ++ [ sshKeys.orange ];
  "secrets/gluster-orange-crt.age".publicKeys = defaults ++ disknodes;

  # google-assistant
  "secrets/google-assistant-client-email.age".publicKeys = defaults ++ kubenodes;
  "secrets/google-assistant-private-key.age".publicKeys = defaults ++ kubenodes;

  # grafana
  "secrets/grafana-secret-key.age".publicKeys = defaults ++ kubenodes;

  # telegram bot
  "secrets/telegram-router-bot-key.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];
  "secrets/telegram-telly-bot-key.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];
  "secrets/telegram-group.age".publicKeys = defaults  ++ [ sshKeys.cloudberry ];

  # LG webos
  "secrets/webos-dev-mode-token.age".publicKeys = defaults ++ kubenodes;

  # netbird
  "secrets/netbird-datastore-key.age".publicKeys = defaults ++ [ sshKeys.lemon ];
  "secrets/netbird-mgmt-client-id.age".publicKeys = defaults ++ [ sshKeys.lemon ];
  "secrets/netbird-mgmt-client-secret.age".publicKeys = defaults ++ [ sshKeys.lemon ];
  "secrets/netbird-coturn-password.age".publicKeys = defaults ++ [ sshKeys.lemon ];
  "secrets/netbird-coturn-secret.age".publicKeys = defaults ++ [ sshKeys.lemon ];
  "secrets/orange-netbird-privatekey.age".publicKeys = defaults ++ [ sshKeys.orange ];
  "secrets/lemon-netbird-privatekey.age".publicKeys = defaults ++ [ sshKeys.lemon ];
  "secrets/cloudberry-netbird-privatekey.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];

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

  # cloudberry
  "secrets/cloudberry-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];
  "secrets/cloudberry-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];
  "secrets/cloudberry-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];

  # continue config (no darwin support in age-template)
  "secrets/continue-config.age".publicKeys = defaults;
}