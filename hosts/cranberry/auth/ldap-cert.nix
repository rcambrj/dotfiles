{ flake, ... }: {
  environment.etc = {
    "ldap.pem".source = flake.lib.ldap-cert;
  };
}