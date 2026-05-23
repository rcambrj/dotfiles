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
  "secrets/cloudflare-tunnel-home.age".publicKeys = defaults ++ kubenodes;
  "secrets/cloudflare-tunnel-hermes.age".publicKeys = defaults ++ [ sshKeys.cherry ];

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

  # oracle email delivery
  "secrets/oracle-cloud-smtp-username.age".publicKeys = defaults ++ kubenodes;
  "secrets/oracle-cloud-smtp-password.age".publicKeys = defaults ++ kubenodes;

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
  "secrets/grafana-admin-password.age".publicKeys = defaults ++ kubenodes;

  # telegram bot
  "secrets/telegram-router-bot-key.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];
  "secrets/telegram-hermes-bot-key.age".publicKeys = defaults ++ [ sshKeys.cherry ];
  "secrets/telegram-telly-bot-key.age".publicKeys = defaults ++ [ sshKeys.cloudberry ];
  "secrets/telegram-group.age".publicKeys = defaults  ++ [ sshKeys.cloudberry sshKeys.cherry ];
  "secrets/telegram-rcambrj-user-id.age".publicKeys = defaults ++ [ sshKeys.cherry ];
  "secrets/telegram-squidlizard-user-id.age".publicKeys = defaults ++ [ sshKeys.cherry ];

  # LG webos
  "secrets/webos-dev-mode-token.age".publicKeys = defaults ++ kubenodes;

  # postgres
  "secrets/postgres-user-radarr.age".publicKeys = defaults ++ kubenodes;
  "secrets/postgres-user-sonarr.age".publicKeys = defaults ++ kubenodes;
  "secrets/postgres-user-backup.age".publicKeys = defaults ++ kubenodes;

  # hermes-agent
  "secrets/hermes-agent.age".publicKeys = defaults ++ [ sshKeys.cherry ];
  "secrets/opencode-go-api-key.age".publicKeys = defaults ++ [ sshKeys.cherry ];

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

  # cloudberry
  "secrets/lemon-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.lemon ];
  "secrets/lemon-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.lemon ];
  "secrets/lemon-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.lemon ];
}
