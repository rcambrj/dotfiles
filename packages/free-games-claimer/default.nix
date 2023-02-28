{ pkgs, system, ... }:
let
  inherit (pkgs)
    lib
    buildNpmPackage
    fetchFromGitHub
    writeShellScript
    firefox
    nodejs
    ;

  rev = "c8cf7362fa2ff92386eee4dc847784d95d7f5195";

  mkScriptWrapper = scriptPath: ''
    #!${lib.getExe pkgs.bash}
    FIREFOX_BIN_PATH="${lib.getExe firefox}" \\
      ${lib.getExe nodejs} ${scriptPath}
  '';

  entrypoints = [
    "epic-games"
    "prime-gaming"
    "gog"
  ];

  platforms = ["x86_64-linux"];
in
if !(lib.elem system platforms)
  then pkgs.writeShellScript "free-games-claimer" "echo system ${system} not supported; exit 1"
  else buildNpmPackage rec {
    pname = "free-games-claimer";
    version = builtins.substring 0 7 rev;

    src = fetchFromGitHub {
      owner = "vogler";
      repo = pname;
      inherit rev;
      hash = "sha256-mJ2l7ixgr+YZSKz4k8SL2OhqDlwxHddqlQXlHrUjZFE=";
    };

    patches = [
      ./patches/0001-specify-DATA_DIR-env-var.patch

      # why not PLAYWRIGHT_BROWSERS_PATH? playwright expects bin to be nested
      # somewhere unpredictable in PLAYWRIGHT_BROWSERS_PATH (it's not a shell PATH)
      ./patches/0002-specify-firefox-bin-path.patch
    ];

    env = {
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
      FIREFOX_BIN_PATH = "${lib.getExe firefox}";
    };

    installPhase =
    let
      outputPath = toString (placeholder "out");
    in
    ''
      npmInstallHook

      mkdir $out/bin
      ${toString (map (entrypoint: ''
        echo "${mkScriptWrapper "${placeholder "out"}/lib/node_modules/free-games-claimer/${entrypoint}.js"}" > $out/bin/${entrypoint}
        chmod +x $out/bin/${entrypoint}
      '') entrypoints)}
    '';

    npmDepsHash = "sha256-ErKwkbix1QurnFtnTYJWjkqORgULWe5WjREk9hI1rV4=";

    dontNpmBuild = true;

    meta = with lib; {
      inherit platforms;
      description = "Automatically claims free games on the Epic Games Store, Amazon Prime Gaming and GOG.";
      homepage = "https://github.com/vogler/free-games-claimer";
      license = licenses.agpl3Only;
      maintainers = with maintainers; [ srounce ];
    };
  }
