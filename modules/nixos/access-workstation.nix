{ flake, pkgs, ... }: {
  nix.settings.trusted-users = [ "rcambrj" ];
  users.users.rcambrj = {
    isNormalUser = true;
    uid = 1001;
    group = "staff";
    home = "/home/rcambrj";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    openssh.authorizedKeys.keys = [ flake.lib.ssh-keys.mbp2024 flake.lib.ssh-keys.linux-vm flake.lib.ssh-keys.mango ];
    hashedPassword = "$y$j9T$BAm5JP1cEarfWQ0R5Fmhr.$Ne1D9ChTvXEGKzJGcO9xtk7yeSKrkYwASHxhmbw8PtB";
  };
  users.groups.staff = {
    gid = 1001;
  };
}