{ config, ... }: {
  users.groups.acme.members = ["nginx"];

  security.acme = {
    acceptTerms = true;
    defaults.email = "robert@cambridge.me";
    # because DHCP-provided NS mangles the response for these domains
    defaults.dnsResolver = "1.1.1.1:53";

    certs."elderberry.cambridge.me" = {
      domain = "elderberry.cambridge.me";
      extraDomainNames = [ "*.elderberry.cambridge.me" ];
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.acme-cloudflare.path;
    };
  };
}