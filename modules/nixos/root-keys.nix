{ flake, ... }: {
  users.users.root.openssh.authorizedKeys.keys = [ flake.lib.ssh-keys.github flake.lib.ssh-keys.mbp2024 flake.lib.ssh-keys.linux-vm flake.lib.ssh-keys.mango ];
}