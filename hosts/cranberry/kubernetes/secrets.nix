{ config, ... }: {
  services.k3s.manifests."10-secrets-ns".content = [
    {
      apiVersion = "v1";
      kind = "Namespace";
      metadata.name = "media";
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

}