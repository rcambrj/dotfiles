{ config, ... }: let
  argoPort = 30276;
in {
  networking.firewall = {
      # https://docs.k3s.io/installation/requirements#networking
    allowedTCPPorts = [
      6443      # apiserver
      2379 2380 # etcd
    ];
    allowedUDPPorts = [
      8472      # flannel
    ];
  };

  services.nginx.virtualHosts."argo-cd.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${toString argoPort}";
    };
  };

  age-template.files.argo-cd-secret = {
    path = "/var/lib/rancher/k3s/server/manifests/argo-cd-secret.yaml";
    vars = {
      oidc_client_secret = config.age.secrets.argo-cd-client-secret-base64.path;
    };
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: argocd-secret
        namespace: argo-cd
        labels:
          app.kubernetes.io/name: argocd-secret
          app.kubernetes.io/part-of: argo-cd
      type: Opaque
      data:
        oidc.clientSecret: $oidc_client_secret
    '';
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--disable=traefik"
    ];
    # https://docs.k3s.io/cli/token
    tokenFile = config.age.secrets.k3s-token.path;

    # https://docs.k3s.io/datastore/ha-embedded#existing-single-node-clusters
    # clusterInit = true;

    manifests = {
      argo-cd.content = let
        version = "v8.1.2";
      in {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          namespace = "kube-system";
          name = "argo-cd";
        };
        spec = {
          inherit version;
          targetNamespace = "argo-cd";
          createNamespace = true;
          chart = "argo-cd";
          repo = "https://argoproj.github.io/argo-helm";
          valuesContent = builtins.toJSON {
            image = {
              tag = version;
            };
            server.service = {
              type = "NodePort";
              nodePortHttp = argoPort;
            };
            dex.enabled = false;
            configs.secret.createSecret = false;
            configs.params."server.insecure" = true;
            configs.cm."url" = "https://argo-cd.media.cambridge.me";
            configs.cm."oidc.config" = builtins.toJSON {
              name = "SSO";
              issuer = "https://dex.home.cambridge.me";
              clientID = "argo-cd";
              clientSecret = "$oidc.clientSecret";
              requestedScopes = ["openid" "profile" "email" "groups"];
              requestedIDTokenClaims = { groups = { essential = true; }; };
            };
          };
        };
      };
    };
  };
}