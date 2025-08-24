{ inputs, perSystem, pkgs, ... }: with pkgs.lib; pkgs.stdenv.mkDerivation (let
  configs = (let
    eval = pkgs.lib.evalModules {
      specialArgs = { inherit inputs perSystem pkgs; };
      modules = [
        ./core.nix

        ./auth.nix
        ./fix-quirky-lidl-lights.nix
        ./google-assistant.nix
        ./lights-and-switches.nix
        ./lovelace.nix
        ./mosquitos.nix
        ./scenery.nix
        ./scenes.nix
        ./ventilation.nix
        ./webos-dev-mode.nix
      ];
    };
    in eval.config
  );

  # https://github.com/NixOS/nixpkgs/blob/5a0711127cd8b916c3d3128f473388c8c79df0da/nixos/modules/services/home-automation/home-assistant.nix#L59
  # Post-process YAML output to add support for YAML functions, like
  # secrets or includes, by naively unquoting strings with leading bangs
  # and at least one space-separated parameter.
  # https://www.home-assistant.io/docs/configuration/secrets/
  format = pkgs.formats.yaml { };
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
in {
  name = "home-assistant-config";
  dontUnpack = true;
  passthru = configs;
  installPhase = let
    yamls = mapAttrs (name: value: renderYAMLFile name value) configs;
  in ''
    mkdir -p $out
  ''
  + concatMapAttrsStringSep "\n" (name: value: ''
    ln -s ${value} $out/${name}
  '') yamls;
})