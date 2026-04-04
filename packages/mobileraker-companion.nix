# inspired by:
# https://github.com/truelecter/hive/blob/76c16b8ddc9c5f24378bf090d7470c2812570517/cells/klipper/packages/mobileraker-companion.nix
# https://github.com/truelecter/hive/blob/76c16b8ddc9c5f24378bf090d7470c2812570517/cells/klipper/sources/generated.nix
#
{
  pkgs,
  ...
}:
with pkgs.lib;
let
  reqs = python-packages:
    with python-packages; [
      # direct requirements.txt
      coloredlogs
      websockets
      requests
      pillow
      python-dateutil
    ];

  pythonEnv = pkgs.python3.withPackages reqs;

  version = "1e866ae25278d574d38e779c1a31a9780a130761";
in
  pkgs.stdenvNoCC.mkDerivation rec {
    pname = "mobileraker-companion";
    inherit version;
    src = pkgs.fetchFromGitHub {
      owner = "Clon1998";
      repo = "mobileraker_companion";
      rev = version;
      fetchSubmodules = false;
      sha256 = "sha256-RcMe/KSN72RUXXGiDkumRIyoXsn0RGRDRZk9mAZCZTU=";
    };

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin $out/lib/${pname}
      cp -r ./ $out/lib/${pname}

      makeWrapper ${pythonEnv}/bin/python $out/bin/mobileraker-companion \
        --add-flags "$out/lib/${pname}/mobileraker.py"
    '';

    meta = {
      description = "Companion for mobileraker, enabling push notification.";
      homepage = "https://github.com/Clon1998/mobileraker_companion";
      platforms = platforms.linux;
      license = licenses.mit;
    };
  }
