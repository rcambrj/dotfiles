{ pkgs, ... }: pkgs.stdenv.mkDerivation rec {
  name = "fluidd-config";
  # https://github.com/fluidd-core/fluidd-config/tags
  version = "v1.2.1";
  src = pkgs.fetchFromGitHub {
    owner = "fluidd-core";
    repo = "fluidd-config";
    tag = version;
    hash = "sha256-MyIAHgSoAm4bhkE0ENGMUni2U87a1svFc3rycU+ga4E";
  };
  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
  '';
}