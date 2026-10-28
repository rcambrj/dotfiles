{ inputs, perSystem, pkgs, ... }: with pkgs.lib; pkgs.stdenv.mkDerivation (let
  eval = pkgs.lib.evalModules {
    specialArgs = { inherit inputs perSystem pkgs; };
    modules = [
      ./core.nix
      ./http.nix

      ./auth.nix
      ./fix-quirky-lidl-lights.nix
      ./outdoor-lights.nix
      ./google-assistant.nix
      ./lights-and-switches.nix
      ./lovelace.nix
      ./mosquitos.nix
      ./prometheus.nix
      ./scenery.nix
      ./scenes.nix
      ./ventilation.nix
      ./webos-dev-mode.nix
    ];
  };
  configs = eval.config;

  # https://github.com/NixOS/nixpkgs/blob/5a0711127cd8b916c3d3128f473388c8c79df0da/nixos/modules/services/home-automation/home-assistant.nix#L59
  # Post-process YAML output to add support for YAML functions, like
  # secrets or includes, by naively unquoting strings with leading bangs
  # and at least one space-separated parameter.
  # https://www.home-assistant.io/docs/configuration/secrets/
  yamlFormat = pkgs.formats.yaml { };
  jsonFormat = pkgs.formats.json { };
  renderYAMLFile =
    fn: yaml:
    pkgs.runCommand fn
      {
        preferLocalBuilds = true;
      }
      ''
        cp ${format.generate fn yaml} $out
        sed -i -e "s/'\!\([a-z_]\+\) \(.*\)'/\!\1 \2/;s/^\!\!/\!/;" $out
      '';
  renderJSONFile =
    fn: json: jsonFormat.generate (baseNameOf fn) json;
in {
  name = "home-assistant-config";
  dontUnpack = true;
  passthru = configs;
  installPhase = let
    files = mapAttrs
      (name: value:
        if (getAttr name eval.options).type == yamlFormat.type
        then renderYAMLFile name value
        else renderJSONFile name value)
      configs;
  in ''
    mkdir -p $out/.storage
  ''
  + concatMapAttrsStringSep "\n" (name: value: ''
    mkdir -p $out/$(dirname ${name})
    ln -s ${value} $out/${name}
  '') files;
})
