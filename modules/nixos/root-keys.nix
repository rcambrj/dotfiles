{ flake, ... }: {
  users.users.root.openssh.authorizedKeys.keys = [ flake.lib.ssh-keys.github flake.lib.ssh-keys.rcambrj flake.lib.ssh-keys.linux-vm ];
}