{ config, ... }:
with config.router;
{
  networking.firewall.allowedTCPPorts = [
    80  # HTTP
    443 # HTTPS
  ];

  services.nginx = {
    enable = true;

    defaultListen = [
      { addr = home-ip; }
      { addr = mgmt-ip; }
    ];

    clientMaxBodySize = "200M";
    proxyTimeout = "300s";

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    # Only allow PFS-enabled ciphers with AES256
    # sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    commonHttpConfig = ''
      proxy_buffering off;

      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
        https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;
    '';
  };
}