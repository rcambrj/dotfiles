{ inputs, ... }: args@{ flake, lib, pkgs, ... }:
let
  vscode = import ../vscode { inherit inputs; } args;
in vscode // {
  imports = [
    ../rcambrj-console
    # ../vscode # requires inputs (see blueprint docs)
    ./gnome.nix
    ./touchpad.nix
    ./brightness.nix
  ];

  home.packages = with pkgs; [
    firefox
    google-chrome
    slack
    discord-canary
    spotify
    signal-desktop
    element-desktop
    # orca-slicer # doesnt build
    # TODO: pia vpn
    rustdesk
  ];
}