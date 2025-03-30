{ config, ... }: {
  services.nginx.virtualHosts."oauth2-proxy.media.cambridge.me" = {
    forceSSL = true;
    useACMEHost = "media.cambridge.me";
    locations."/" = {
      proxyWebsockets = true;
      proxyPass = "http://localhost:4180";
    };
  };

  age-template.files.oauth2-proxy-env = {
    vars = {
      oauth2_proxy_client_secret = config.age.secrets.cranberry-oauth2-proxy-client-secret.path;
      oauth2_proxy_cookie_secret = config.age.secrets.cranberry-oauth2-proxy-cookie-secret.path;
    };
    content = ''
      OAUTH2_PROXY_CLIENT_ID=cranberry-oauth2-proxy
      OAUTH2_PROXY_CLIENT_SECRET=$oauth2_proxy_client_secret
      OAUTH2_PROXY_COOKIE_SECRET=$oauth2_proxy_cookie_secret
    '';
  };

  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    keyFile = config.age-template.files.oauth2-proxy-env.path;
    # clientID = "";     # see keyFile. this gets clobbered https://github.com/NixOS/nixpkgs/blob/7100415/nixos/modules/services/security/oauth2-proxy.nix#L567
    # clientSecret = ""; # see keyFile.
    # secret = "";       # see keyFile. cookie-secret. must be exactly 16, 24 or 32 chars.
    reverseProxy = true;
    email.domains = ["*"];
    nginx = {
      domain = "oauth2-proxy.media.cambridge.me";
    };
    extraConfig = {
      # show-debug-on-error = true;
      approval-prompt = "none"; # default=force
      skip-provider-button = true;
      oidc-issuer-url = "https://dex.home.cambridge.me";
      cookie-csrf-per-request = true;
      cookie-domain = [ ".media.cambridge.me" ];
      whitelist-domain = [ ".media.cambridge.me" ];

      skip-oidc-discovery = true;
      # inferred from OIDC .well-known/openid-configuration (see skip-oidc-discovery)
      # with discovery enabled, oauth2-proxy won't come up if dex isn't ready
      oidc-jwks-url = "https://dex.home.cambridge.me/keys";
      login-url = "https://dex.home.cambridge.me/auth";
      redeem-url = "https://dex.home.cambridge.me/token";
      validate-url = "https://dex.home.cambridge.me/token/introspect";

      redirect-url = "https://oauth2-proxy.media.cambridge.me/oauth2/callback";
    };
  };
}