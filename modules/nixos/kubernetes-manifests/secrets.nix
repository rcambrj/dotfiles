{ config, lib, ... }: with lib; let
  cfg = config.services.kubernetes-manifests;
in {
  options = {};
  config = mkIf cfg.enable ({
    age.secrets = {
      acme-cloudflare.file = ../../../secrets/acme-cloudflare.age;
      kubernetes-oauth2-proxy-client-secret.file = ../../../secrets/kubernetes-oauth2-proxy-client-secret.age;
      kubernetes-oauth2-proxy-cookie-secret.file = ../../../secrets/kubernetes-oauth2-proxy-cookie-secret.age;
      longhorn-backup-b2-apikey.file = ../../../secrets/longhorn-backup-b2-apikey.age;
      longhorn-backup-b2-secret.file = ../../../secrets/longhorn-backup-b2-secret.age;
      pia-vpn-pass.file = ../../../secrets/pia-vpn-pass.age;
      pia-vpn-user.file = ../../../secrets/pia-vpn-user.age;
      seaweedfs-ca-crt = mkDefault {
        file = ../../../secrets/seaweedfs-ca-crt.age;
        mode = "444";
      };
      kubernetes-seaweedfs-admin-key.file = ../../../secrets/kubernetes-seaweedfs-admin-key.age;
      kubernetes-seaweedfs-admin-crt.file = ../../../secrets/kubernetes-seaweedfs-admin-crt.age;
    };

    services.k3s.manifests."10-secrets-ns".content = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "media";
      }
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "cert-manager";
      }
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "oauth2-proxy";
      }
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "longhorn-system";
      }
    ];

    age-template.files."20-media-vpn-secret" = {
      path = "/var/lib/rancher/k3s/server/manifests/20-media-vpn-secret.yaml";
      vars = {
        user = config.age.secrets.pia-vpn-user.path;
        pass = config.age.secrets.pia-vpn-pass.path;
      };
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: vpn
          namespace: media
        immutable: true
        stringData:
          user: $user
          pass: $pass
      '';
    };

    age-template.files."20-cloudflare-token" = {
      path = "/var/lib/rancher/k3s/server/manifests/20-cloudflare-token.yaml";
      vars = {
        token = config.age.secrets.acme-cloudflare.path;
      };
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: cloudflare-token
          namespace: cert-manager
        immutable: true
        stringData:
          token: $token
      '';
    };

    age-template.files."20-oauth2-proxy" = {
      path = "/var/lib/rancher/k3s/server/manifests/20-oauth2-proxy.yaml";
      vars = {
        clientsecret = config.age.secrets.kubernetes-oauth2-proxy-client-secret.path;
        # cookie-secret. must be exactly 16, 24 or 32 chars.
        cookiesecret = config.age.secrets.kubernetes-oauth2-proxy-cookie-secret.path;
      };
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: oauth2-proxy
          namespace: oauth2-proxy
        immutable: true
        stringData:
          client-secret: $clientsecret
          cookie-secret: $cookiesecret
      '';
    };

    age-template.files."20-longhorn-backup-b2" = {
      path = "/var/lib/rancher/k3s/server/manifests/20-longhorn-backup-b2.yaml";
      vars = {
        apikey = config.age.secrets.longhorn-backup-b2-apikey.path;
        secret = config.age.secrets.longhorn-backup-b2-secret.path;
      };
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: longhorn-backup-b2
          namespace: longhorn-system
        immutable: true
        stringData:
          AWS_ENDPOINTS: s3.eu-central-003.backblazeb2.com
          AWS_ACCESS_KEY_ID: $apikey
          AWS_SECRET_ACCESS_KEY: $secret
      '';
    };

    age-template.files."20-seaweedfs-admin-certs" = {
      path = "/var/lib/rancher/k3s/server/manifests/20-seaweedfs-admin-certs.yaml";
      vars = {
        cacrt = config.age.secrets.seaweedfs-ca-crt.path;
        adminkey = config.age.secrets.kubernetes-seaweedfs-admin-key.path;
        admincrt = config.age.secrets.kubernetes-seaweedfs-admin-crt.path;
      };
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: admin-certs
          namespace: seaweedfs
        immutable: true
        stringData:
          ca.crt: "$cacrt"
          admin.key: "$adminkey"
          admin.crt: "$admincrt"
      '';
    };
  });
}