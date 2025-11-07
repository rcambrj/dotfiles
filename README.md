# dotfiles

This repository contains my NixOS-based homelab infrastructure implementing a Kubernetes cluster with GlusterFS storage, network routing with WAN failover, home automation via Home Assistant, media services, 3D printer management, GitOps deployment through ArgoCD, LDAP authentication with OAuth2/OIDC integration, monitoring with Prometheus/Grafana, automated backups to cloud storage, and infrastructure-as-code using Nix flakes. The system spans multiple physical nodes with both on-premises and off-site components, using age encryption for secrets management and supporting both x86_64 and ARM architectures.

## Repository structure
Follows [numtide/blueprint](https://github.com/numtide/blueprint/) with some extras:

* `hosts/` for `nixosConfigurations` and `darwinConfigurations`
* `modules/` for `nixosModules` and `darwinModules`
* `packages/` for `packages`
* `kubernetes/` for ArgoCD apps
* `secrets/` for age secrets, see `secrets.nix`

### Machine configurations
Located in `hosts/`

* `blueberry`: a kubernetes and gluster node
* `cloudberry`: the uplink router with WAN failover
* `cranberry`: a kubernetes and gluster node
* `elderberry`: a 3D printer
* `mango`: a NixOS laptop (abandoned for now, main workstation is a [Macbook](https://github.com/rcambrj/nix-macbook), maybe I'll come back to it some day)
* `minimal-*`: NixOS configurations for debugging and adopting new machines
* `orange`: a kubernetes (no workloads) and gluster (no storage) node located offsite

> [!NOTE]
> Why is [Macbook](https://github.com/rcambrj/nix-macbook) in a different repository? It used to be that `nixos-unstable` would frequently break for darwin - much more frequently than for nixos proper, so in order to keep darwin on a working version, it's in a different flake with its own nixpkgs input. `nixos-unstable` has been better on darwin recently, but I haven't got around to merging the two.

### Home Manager configurations

* `modules/home/rcambrj-console`: a portable configuration for use on workstations and servers (although I think it's somewhat bloated for use on servers). This is consumed by [Macbook](https://github.com/rcambrj/nix-macbook).
* `modules/home/rcambrj-graphical`: a configuration for my workstation's graphical interface (originally built for `mango`)
* `modules/home/vscode`: the configuration for my text editor. Consumed by `rcambrj-graphical` and [Macbook](https://github.com/rcambrj/nix-macbook)

## Preparing a new machine

### Prepare a headless bare metal machine on split USB storage

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

### Prepare a headless bare metal machine with AIO disk

1. Create a new configuration in `/hosts` which uses `disk-aio.nix`
1. Boot `minimal-intel` with two-USB method (aarch64/raspi untested)
    > Note: nixos graphical/livecd has limited free space for the nix store, so cannot be used

1. Enable swap, if the machine is particularly underpowered
    ```bash
    fdisk
    # ...create a swap partition

    sudo swapon /dev/mmcblk0p1
    ```
1. Ensure that the disk target is correct
    ```
    disko.devices.disk.disk1.device = "/dev/disk/by-id/..."
    ```
1. Partition the disk
    ```bash
    sudo nix run github:nix-community/disko/latest -- --flake "github:rcambrj/dotfiles#host" --mode destroy,format,mount --yes-wipe-all-disks
    
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