{ ... }: {
  imports = [
    ./google-assistant.nix
    ./home-assistant.nix
    ./lights-and-switches.nix
    ./mosquitos.nix
    ./scenes.nix
    ./ventilation.nix
    ./webos-dev-mode.nix
    ./fix-quirky-lidl-lights.nix
    ./lovelace.nix
  ];
}