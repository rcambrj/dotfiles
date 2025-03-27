# dotfiles

Records configuration for nix machines, builds images for bare metal machines and deploys updates to cloud machines. Probably also has some useful modules and packages.

## To set up a headless bare metal machine

> Requires two USB sticks.

1. Run the Github action to build minimal-intel or minimal-raspi
1. Burn [the resulting image](https://github.com/rcambrj/dotfiles/releases/tag/release) to a USB stick
1. Create `/hosts/{hostname}/configuration.nix`
1. Add minimum configuration to `configuration.nix`:
    ```
    imports = [
        flake.nixosModules.base
        flake.nixosModules.access-server
        flake.nixosModules.common
        flake.nixosModules.bare-metal-usb
        flake.nixosModules.config-intel
        # or
        flake.nixosModules.config-raspi
    ];

    networking.hostName = "{hostname}";
    ```
1. Prepare **a second USB stick** with a single FAT32 partition named `NIXOSCONF`
1. Run `ssh-keygen` to generate a key pair
1. Put the resulting private key on this second USB stick
1. Put the resulting public key into Github repository deploy keys
1. Plug both USB sticks into a machine and switch it on
1. SSH to `minimal-intel-nomad` or `minimal-raspi-nomad`
1. Run `sudo nixos-rebuild switch --flake github:rcambrj/dotfiles#{hostname}`

## Building locally on MacOS

1. workaround [a bug with nix-darwin and auto-optimise-store](https://github.com/NixOS/nix/issues/7273)
   ```
   nix.settings.auto-optimise-store = false;
   ```
1. configure nix-darwin with linux-builder (remove the host system from the two lists)
    ```
    nix.linux-builder.enable = true;
    nix.linux-builder.systems = ["x86_64-linux" "aarch64-linux" "armv7l-linux"];
    nix.linux-builder.maxJobs = 10;
    nix.linux-builder.config = ({ pkgs, ... }:{
        boot.binfmt.emulatedSystems = ["x86_64-linux" "aarch64-linux" "armv7l-linux"];
    });
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    ```
1. run the builder on MacOS
    ```shell
    make build machine=blueberry
    ```

## Edit a secret

```
make edit-secret name=foo
```