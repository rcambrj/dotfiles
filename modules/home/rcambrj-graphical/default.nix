{ flake, pkgs, ... }: {
  imports = [
    ../rcambrj-console
    ../vscode
  ];

  home.packages = with pkgs; [
    _1password-gui
    firefox
    google-chrome
    slack
    discord-canary
    spotify
    telegram-desktop
    whatsapp-for-linux
    signal-desktop
    element-desktop
    # orca-slicer
    # TODO: pia vpn
    netbird
    rustdesk
  ];
}