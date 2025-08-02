{ inputs, perSystem, pkgs, ... }: with pkgs.lib; pkgs.stdenv.mkDerivation (let
  configs = (let
    eval = pkgs.lib.evalModules {
      specialArgs = { inherit inputs perSystem pkgs; };
      modules = [
        ./core.nix
        ./auth.nix
        ./mosquitos.nix
        ./lights-and-switches.nix
        ./fix-quirky-lidl-lights.nix
        ./google-assistant.nix
        ./scenes.nix
        ./ventilation.nix
        ./webos-dev-mode.nix
        ./lovelace.nix
      ];
    };
    in eval.config
  );
in {
  name = "home-assistant-config";
  dontUnpack = true;
  passthru = configs;
  installPhase = let
    yamls = mapAttrs (name: value: (pkgs.formats.yaml { }).generate name value) configs;
  in ''
    mkdir -p $out
  ''
  + concatMapAttrsStringSep "\n" (name: value: ''
    ln -s ${value} $out/${name}
  '') yamls;
})