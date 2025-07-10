{ config, ... }: {
  users.groups.acme.members = ["nginx"];

  age-template.files.acme-env-cloudflare = {
    vars = {
      token = config.age.secrets.acme-cloudflare.path;
    };
    content = ''
      CLOUDFLARE_DNS_API_TOKEN=$token
    '';
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "robert@cambridge.me";
    # because DHCP-provided NS mangles the response for these domains
    defaults.dnsResolver = "1.1.1.1:53";

    certs."home.cambridge.me" = {
      domain = "home.cambridge.me";
      extraDomainNames = [ "*.home.cambridge.me" ];
      dnsProvider = "cloudflare";
      environmentFile = config.age-template.files.acme-env-cloudflare.path;
    };
    certs."fdm.cambridge.me" = {
      domain = "fdm.cambridge.me";
      extraDomainNames = [ "*.fdm.cambridge.me" ];
      dnsProvider = "cloudflare";
      environmentFile = config.age-template.files.acme-env-cloudflare.path;
    };
  };
}