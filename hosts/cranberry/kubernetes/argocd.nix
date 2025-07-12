{ config, pkgs, ... }: let
  port = 30276;

  # argoVersion should equal the one provided by the chart
  chartVersion = "v8.1.2";
  argoVersion = "v3.0.6";

  argoRepo = pkgs.fetchFromGitHub {
    owner = "argoproj";
    repo = "argo-cd";
    tag = argoVersion;
    hash = "sha256-I5xO66ZDinEoljT18kXukEW+rmcXaKui/Ha9nvEjxgA";
  };
  allNamespaces = pkgs.runCommand "argocd-all-namespaces" {} ''
    ${pkgs.kustomize}/bin/kustomize build ${argoRepo}/examples/k8s-rbac/argocd-server-applications -o $out
  '';
in {
  services.nginx.virtualHosts."argocd.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${toString port}";
    };
  };

  services.k3s.manifests."10-argocd-ns".content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "argocd";
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

  age-template.files.argocd-dotfiles-repo = {
    path = "/var/lib/rancher/k3s/server/manifests/argocd-dotfiles-repo.yaml";
    vars = {
      ssh_key = config.age.secrets.argocd-ssh-key.path;
    };
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: dotfiles-repo
        namespace: argocd
        labels:
          argocd.argoproj.io/secret-type: repository
      stringData:
        url: git@github.com:rcambrj/dotfiles
        sshPrivateKey: "$ssh_key"
    '';
  };

  # services.k3s.autoDeployCharts breaks when building on arm64
  # so just use K3s' HelmChart resource in an Addon manifest
  services.k3s.manifests.argocd.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      namespace = "kube-system";
      name = "argocd";
      finalizers = [
        "wrangler.cattle.io/on-helm-chart-remove"
      ];
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
          nodePortHttp = port;
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

  services.k3s.manifests.argocd-all-namespaces = {
    target = "argocd-all-namespaces.yaml";
    source = allNamespaces;
  };

  services.k3s.manifests.argocd-dotfiles-application.content = {
    apiVersion =  "argoproj.io/v1alpha1";
    kind = "Application";
    metadata = {
      name = "dotfiles";
      namespace = "argocd";
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ];
    };
    spec = {
      project = "default";
      source = {
        repoURL = "git@github.com:rcambrj/dotfiles";
        targetRevision = "HEAD";
        path = "kubernetes/bootstrap";
      };
      destination = {
        server =  "https://kubernetes.default.svc";
        namespace = "argocd";
      };
      syncPolicy = {
        automated = {
          prune = true;
          selfHeal = true;
        };
      };
    };
  };
}