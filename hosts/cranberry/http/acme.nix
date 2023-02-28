{ config, ... }: {
  users.groups.acme.members = ["nginx"];

  security.acme = {
    acceptTerms = true;
    defaults.email = "robert@cambridge.me";
    # because DHCP-provided NS mangles the response for these domains
    defaults.dnsResolver = "1.1.1.1:53";

    certs."media.cambridge.me" = {
      domain = "media.cambridge.me";
      extraDomainNames = [ "*.media.cambridge.me" ];
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.acme-cloudflare.path;
    };
  };
}