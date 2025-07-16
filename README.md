# dotfiles

Records configuration for nix machines, builds images for bare metal machines and deploys updates to cloud machines. Probably also has some useful modules and packages.

## Prepare a headless bare metal machine on split USB storage

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
        flake.nixosModules.bare-metal
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

## Prepare a headless bare metal machine with AIO disk

1. Create a new configuration in `/hosts` which uses `disk-aio.nix`
1. Boot `minimal-intel` with two-USB method (aarch64/raspi untested)
    > Note: nixos graphical/livecd has limited free space for the nix store, so cannot be used

1. Enable swap, if the machine is particularly underpowered
    ```bash
    fdisk
    # ...create a swap partition

    sudo swapon /dev/mmcblk0p1
    ```
1. Partition the disk
    ```bash
    sudo nix run github:nix-community/disko/latest -- --flake "github:rcambrj/dotfiles#host" --mode destroy,format,mount
    
    # confirm fs labels are correct (vs part labels)
    lsblk -o name,mountpoint,label,size,uuid
    ```
1. Mount the partitions necessary for installation in a chroot
    ```bash
    sudo mkdir -p /mnt/install
    sudo mount /dev/path/to/root/partition /mnt/install
    sudo mkdir -p /mnt/install/boot
    sudo mount /dev/path/to/boot/partition /mnt/install/boot
    ```
1. Install nixos
    ```bash
    sudo nixos-install --root /mnt/install --flake "github:rcambrj/dotfiles#host" --no-root-passwd
    ```

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