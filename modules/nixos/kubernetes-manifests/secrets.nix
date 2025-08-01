{ config, lib, ... }: with lib; let
  cfg = config.services.kubernetes-manifests;
in {
  options = {};
  config = mkIf cfg.enable ({
    age.secrets = {
      acme-cloudflare.file = ../../../secrets/acme-cloudflare.age;

      kubernetes-oauth2-proxy-client-secret.file = ../../../secrets/kubernetes-oauth2-proxy-client-secret.age;
      kubernetes-oauth2-proxy-cookie-secret.file = ../../../secrets/kubernetes-oauth2-proxy-cookie-secret.age;

      pia-vpn-pass.file = ../../../secrets/pia-vpn-pass.age;
      pia-vpn-user.file = ../../../secrets/pia-vpn-user.age;

      google-assistant-client-email.file = ../../../secrets/google-assistant-client-email.age;
      google-assistant-private-key.file  = ../../../secrets/google-assistant-private-key.age;

      telegram-bot-api-key.file = ../../../secrets/telegram-bot-api-key.age;
      telegram-group.file       = ../../../secrets/telegram-group.age;
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
        metadata.name = "home-assistant";
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
        stringData:
          client-secret: $clientsecret
          cookie-secret: $cookiesecret
      '';
    };

    age-template.files."20-home-assistant" = {
      path = "/var/lib/rancher/k3s/server/manifests/20-home-assistant.yaml";
      vars = {
        ga_email = config.age.secrets.google-assistant-client-email.path;
        ga_pkey  = config.age.secrets.google-assistant-private-key.path;

        tg_api_key = config.age.secrets.telegram-bot-api-key.path;
        tg_group   = config.age.secrets.telegram-group.path;
      };
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: home-assistant
          namespace: home-assistant
        stringData:
          secrets.yaml: |-
            google_assistant_client_email: "$ga_email"
            google_assistant_private_key: "$ga_pkey"

            telegram_bot_api_key: "$tg_api_key"
            telegram_group: "$tg_group"
      '';
    };
  });
}