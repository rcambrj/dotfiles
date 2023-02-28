{ ... }: {
  imports = [
    ./google-assistant.nix
    ./home-assistant.nix
    ./lights-and-switches.nix
    ./mosquitos.nix
    ./scenes.nix
    ./ventilation.nix
    ./webos-dev-mode.nix
    ./fix-bathroom-mirror-light.nix
    ./lovelace.nix
  ];
}