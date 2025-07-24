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
        type: Opaque
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
        type: Opaque
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
        type: Opaque
        stringData:
          client-secret: $clientsecret
          cookie-secret: $cookiesecret
      '';
    };

    age-template.files."20-longhorn-backup-b2" = {
      path = "/var/lib/rancher/k3s/server/manifests/20-longhorn-backup-b2.yaml";
      vars = {
        apikey = config.age.secrets.longhorn-backup-b2-apikey.path;
        # cookie-secret. must be exactly 16, 24 or 32 chars.
        secret = config.age.secrets.longhorn-backup-b2-secret.path;
      };
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: longhorn-backup-b2
          namespace: longhorn-system
        type: Opaque
        stringData:
          AWS_ENDPOINTS: s3.eu-central-003.backblazeb2.com
          AWS_ACCESS_KEY_ID: $apikey
          AWS_SECRET_ACCESS_KEY: $secret
      '';
    };
  });
}