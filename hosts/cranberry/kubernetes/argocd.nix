{ pkgs, ... }: let
  # argoVersion should equal the one provided by the chart
  chartVersion = "v8.1.2";
  argoVersion = "v3.0.6";

  argoRepo = pkgs.fetchFromGitHub {
    owner = "argoproj";
    repo = "argo-cd";
    tag = argoVersion;
  };
in {
  services.nginx.virtualHosts."argocd.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${toString argoPort}";
    };
  };

  age-template.files.argocd-secret = {
    path = "/var/lib/rancher/k3s/server/manifests/argocd-secret.yaml";
    vars = {
      session_key = config.age.secrets.argocd-session-key.path;
      oidc_client_secret = config.age.secrets.argocd-client-secret.path;
    };
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: argocd-secret
        namespace: argocd
        labels:
          app.kubernetes.io/name: argocd-secret
          app.kubernetes.io/part-of: argocd
      type: Opaque
      stringData:
        server.secretkey: $session_key
        oidc.clientSecret: $oidc_client_secret
    '';
  };

  age-template.files.argocd-repo-creds = {
    path = "/var/lib/rancher/k3s/server/manifests/argocd-repo-creds.yaml";
    vars = {
      ssh_key = config.age.secrets.argocd-ssh-key.path;
    };
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: argocd-repo-creds
        namespace: argocd
        labels:
          argocd.argoproj.io/secret-type: repo-creds
      stringData:
        url: git@github.com:rcambrj/home
        type: helm
        sshPrivateKey: "$ssh_key"
    '';
  };

  services.k3s.manifests.argocd.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      namespace = "kube-system";
      name = "argocd";
    };
    spec = {
      targetNamespace = "argocd";
      createNamespace = true;
      version = chartVersion;
      chart = "argo-cd";
      repo = "https://argoproj.github.io/argo-helm";
      valuesContent = builtins.toJSON {
        image = {
          tag = chartVersion;
        };
        server.service = {
          type = "NodePort";
          nodePortHttp = argoPort;
        };
        dex.enabled = false;
        configs.secret.createSecret = false;
        configs.params."server.insecure" = true;
        configs.params."application.namespaces" = "*";
        configs.cm."url" = "https://argocd.media.cambridge.me";
        configs.cm."oidc.config" = builtins.toJSON {
          name = "SSO";
          issuer = "https://dex.home.cambridge.me";
          clientID = "argocd";
          clientSecret = "$oidc.clientSecret";
          requestedScopes = ["openid" "profile" "email" "groups"];
          requestedIDTokenClaims = { groups = { essential = true; }; };
        };
        configs.rbac."policy.csv" = ''
          g, argocd, role:admin
        '';
      };
    };
  };
  # services.k3s.manifests.argocd-clusterrole.source = builtins.fetchUrl "https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/${argoVersion}/examples/k8s-rbac/argocd-server-applications/argocd-server-rbac-clusterrole.yaml"
}