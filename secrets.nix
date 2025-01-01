let
  sshKeys = import ./lib/ssh-keys.nix;
  defaults = [ sshKeys.mbp2024 sshKeys.linux-vm sshKeys.mango ];
in {
  "secrets/acme-cloudflare.age".publicKeys = defaults ++ [ sshKeys.cranberry sshKeys.blueberry sshKeys.coconut ];
  "secrets/ldap-admin-rw-password.age".publicKeys = defaults ++ [ sshKeys.cranberry sshKeys.blueberry sshKeys.coconut ];
  "secrets/ldap-admin-ro-password.age".publicKeys = defaults ++ [ sshKeys.cranberry sshKeys.blueberry sshKeys.coconut ];

  # oauth2 apps
  "secrets/blueberry-oauth2-proxy-client-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/cranberry-oauth2-proxy-client-secret.age".publicKeys = defaults ++ [ sshKeys.blueberry sshKeys.cranberry ];

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
  "secrets/free-games-claimer-vnc.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/influxdb-admin-password.age".publicKeys = defaults ++ [ sshKeys.blueberry ];
  "secrets/influxdb-admin-token.age".publicKeys = defaults ++ [ sshKeys.blueberry ];

  # cranberry
  "secrets/pia-vpn.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.cranberry ];
  "secrets/cranberry-oauth2-proxy-cookie-secret.age".publicKeys = defaults ++ [ sshKeys.cranberry ];

  # coconut
  "secrets/photoprism-sftp-password.age".publicKeys = defaults ++ [ sshKeys.coconut ];
  "secrets/photoprism-backup-bucket.age".publicKeys = defaults ++ [ sshKeys.coconut ];
  "secrets/photoprism-backup-credentials.age".publicKeys = defaults ++ [ sshKeys.coconut ];
  "secrets/photoprism-backup-encryption-key.age".publicKeys = defaults ++ [ sshKeys.coconut ];
}