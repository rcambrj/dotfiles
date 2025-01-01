{ flake, ... }: {
  security.sudo.wheelNeedsPassword = false;
  services.openssh.enable = true;
  networking.firewall.enable = true;

  nix.settings.trusted-users = [ "root" "nixos" ];
  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "nixos";
    home = "/home/nixos";
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    openssh.authorizedKeys.keys = [ flake.lib.ssh-keys.mbp2024 flake.lib.ssh-keys.linux-vm flake.lib.ssh-keys.mango ];
    hashedPassword = "$y$j9T$Zj3afb7iVGY2BoBozFCht0$3GHzjwXx.Z740jgcMWJh0QceQzEXFUEu/WGj7YVNy1/";
  };
  users.groups.nixos = {
    gid = 1000;
  };
}