{ flake, pkgs, ... }: {
  imports = [
    ../rcambrj-console
    ../vscode
  ];

  home.packages = with pkgs; [
    firefox
    google-chrome
    slack
    discord-canary
    spotify
    telegram-desktop
    whatsapp-for-linux
    signal-desktop
    element-desktop
    # orca-slicer # doesnt build
    # TODO: pia vpn
    netbird
    rustdesk
  ];
}