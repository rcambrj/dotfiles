# dotfiles

This repository contains my NixOS-based homelab infrastructure. It's a collection of configurations for multiple physical machines running various services: a Kubernetes cluster with GlusterFS storage, a network router with dual WAN failover, home automation, 3D printer management, and more. Everything is managed through Nix flakes with age-encrypted secrets.

## Table of Contents

- [What is this?](#what-is-this)
- [Repository Structure](#repository-structure)
- [Machine Configurations](#machine-configurations-hosts)
- [Home Manager Configurations](#home-manager-configurations-moduleshome)
- [NixOS Modules](#nixos-modules-modulesnixos)
- [Kubernetes Applications](#kubernetes-applications-kubernetes)
- [Packages](#packages-packages)
- [Library](#library-lib)
- [Secrets Management](#secrets-management)
- [Quick Start](#quick-start)
- [Common Workflows](#common-workflows)
- [Makefile Commands](#makefile-commands)
- [Checks & Validation](#checks--validation)
- [Notes & Quirks](#notes--quirks)

## What is this?

This is my personal homelab infrastructure, managed entirely through Nix. The setup spans multiple physical locations with:

- **Kubernetes cluster** (k3s) with GlusterFS distributed storage across multiple nodes
- **Network router** running NixOS with dual WAN failover, SQM, VLANs, and VPN
- **Home automation** via Home Assistant with ESPHome devices
- **3D printer** management with Klipper and Fluidd
- **Media stack** for entertainment
- **Monitoring** with Prometheus and Grafana
- **Automated backups** to cloud storage
- **GitOps deployment** through ArgoCD
- **LDAP authentication** with OAuth2/OIDC integration

The infrastructure runs on a mix of x86_64 and ARM hardware, with both on-premises and off-site components.

## Repository Structure

Follows [numtide/blueprint](https://github.com/numtide/blueprint/) with some additions:

```
.
├── hosts/           # NixOS and Darwin configurations per machine
├── modules/
│   ├── home/        # Home Manager configurations
│   └── nixos/       # Reusable NixOS modules
├── packages/        # Custom packages and configurations
├── kubernetes/      # ArgoCD-managed Kubernetes manifests
├── secrets/         # Age-encrypted secrets
├── lib/             # Utility functions
├── checks/          # Flake checks (tests)
├── flake.nix        # Main flake entry point
└── secrets.nix      # Age secret definitions
```

## Machine Configurations (`hosts/`)

Each host directory contains the NixOS configuration for a specific machine, including hardware-specific settings and enabled services.

### Production Hosts

| Host | Role | Architecture | Notes |
|------|------|--------------|-------|
| `blueberry` | Kubernetes + Gluster node | x86_64 | Mac Mini 2011, Intel i7 |
| `cranberry` | Kubernetes + Gluster node | x86_64 | TOPTON 4-port |
| `orange` | Kubernetes + Gluster node | x86_64 | Off-site location, connected via VPN |
| `cloudberry` | Router / gateway | x86_64 | TOPTON 4-port, handles routing, WAN failover, VPN |
| `elderberry` | 3D printer | x86_64 | Dell Wyse 3040, runs Klipper + Fluidd |
| `lemon` | spare | x86_64 |  |
| `cherry` | spare | x86_64 |  |

### Ephemeral Hosts

| Host | Purpose |
|------|---------|
| `minimal-cloud` | Minimal configuration for cloud/VPS deployment |
| `minimal-intel` | Minimal Intel hardware configuration |
| `minimal-raspi` | Minimal Raspberry Pi configuration |

### Abandoned

| Host | Status |
|------|--------|
| `strawberry` | Lightweight agent | x86_64 | Former K8s node, hardware too weak for etcd, might come back as an agent |
| `mango` | NixOS laptop configuration (abandoned - main workstation is now a [MacBook](https://github.com/rcambrj/nix-macbook)) |

> [!NOTE]
> Why is the MacBook in a separate repository? `nixos-unstable` used to break for Darwin much more frequently than for NixOS proper. To keep Darwin on a working version, it's in a separate flake with its own nixpkgs input. `nixos-unstable` has been better on Darwin recently, but I haven't gotten around to merging the two.

## Secrets Management

All secrets are encrypted using **agenix** with **agenix-template** for templating. Secrets are stored in `secrets/` and defined in `secrets.nix`, which maps each encrypted file to the SSH public keys that can decrypt it. Machine-specific secrets follow the pattern `{hostname}-{service}.age`.

## Common Workflows

### Building locally on macOS

1. See macOS-specific workarounds at https://github.com/rcambrj/nix-macbook

2. Configure nix-darwin with linux-builder (remove the host system from the two lists):
   ```nix
   nix.linux-builder.enable = true;
   nix.linux-builder.systems = ["x86_64-linux" "aarch64-linux" "armv7l-linux"];
   nix.linux-builder.maxJobs = 10;
   nix.linux-builder.config = ({ pkgs, ... }: {
     boot.binfmt.emulatedSystems = ["x86_64-linux" "aarch64-linux" "armv7l-linux"];
   });
   nix.settings.experimental-features = [ "nix-command" "flakes" ];
   ```

3. Run the builder:
   ```bash
   make build machine=blueberry
   ```

### Deploying to remote hosts

```bash
# Build and switch on remote host (builds locally, copies closure)
make remote-switch machine=blueberry

# Or more directly:
nixos-rebuild switch --target-host blueberry --flake .#blueberry --sudo
```

### Preparing a new machine

#### Adopting a cloud machine

```bash
# install a minimal system
nix run github:nix-community/nixos-anywhere -- --flake .#minimal-cloud --target-host ubuntu@fruit

# then install the full system
nixos-rebuild switch --flake .#host --target-host host --sudo
```

#### Bare metal machine with split USB storage (requires two USB sticks)

1. Run the GitHub action to build `minimal-intel` or `minimal-raspi`
2. Burn [the resulting image](https://github.com/rcambrj/dotfiles/releases/tag/release) to a USB stick
3. Create `/hosts/{hostname}/configuration.nix`:
   ```nix
   imports = [
     flake.nixosModules.base
     flake.nixosModules.access-server
     flake.nixosModules.common
     flake.nixosModules.bare-metal
     flake.nixosModules.config-intel  # or config-raspi
   ];

   networking.hostName = "{hostname}";
   ```
4. Prepare **a second USB stick** with a single FAT32 partition named `NIXOSCONF`
5. Generate SSH key pair: `ssh-keygen`
6. Put the private key on the second USB stick
7. Add the public key to the repository deploy keys
8. Plug both USB sticks into the machine and boot
9. SSH to `minimal-intel-nomad` or `minimal-raspi-nomad`
10. Deploy:
    ```bash
    sudo nixos-rebuild switch --flake github:rcambrj/dotfiles#{hostname}
    ```

#### Bare metal machine with AIO disk (single USB stick)

1. Create a new configuration in `/hosts` that uses `disko-standard.nix`
2. Boot `minimal-intel` with the two-USB method above
   
   > Note: NixOS graphical/livecd has limited free space for the nix store, so cannot be used

3. Enable swap if the machine is underpowered:
   ```bash
   fdisk
   # ...create a swap partition
   sudo swapon /dev/mmcblk0p1
   ```

4. Ensure the disk target is correct in your disko config:
   ```nix
   disko.devices.disk.disk1.device = "/dev/disk/by-id/..."
   ```

5. Partition and format the disk:
   ```bash
   sudo nix run github:nix-community/disko/latest -- --flake "github:rcambrj/dotfiles#host" --mode destroy,format,mount --yes-wipe-all-disks
   
   # Confirm fs labels are correct (vs part labels)
   lsblk -o name,mountpoint,label,size,uuid
   ```

6. Mount partitions for chroot installation:
   ```bash
   sudo mkdir -p /mnt/install
   sudo mount /dev/path/to/root/partition /mnt/install
   sudo mkdir -p /mnt/install/boot
   sudo mount /dev/path/to/boot/partition /mnt/install/boot
   ```

7. Install NixOS:
   ```bash
   sudo nixos-install --root /mnt/install --flake "github:rcambrj/dotfiles#host" --no-root-passwd
   ```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make clean` | Remove build results (`result` symlink) |
| `make check` | Validate flake (show outputs + run checks) |
| `make build-image machine=NAME` | Build NixOS image for specified machine |
| `make remote-switch machine=NAME` | Deploy to remote host |

## Notes & Quirks

### Hardware-specific issues

**Dell Wyse 3040 (elderberry)** - Blacklists required for `dw_dmac` and `dw_dmac_core` modules to prevent hangs on reboot:
```nix
boot.extraModprobeConfig = ''
  blacklist dw_dmac
  blacklist dw_dmac_core
  install dw_dmac /bin/true
  install dw_dmac_core /bin/true
'';
```

**Mac Mini 2011 (blueberry)** - Built-in network port is fried, uses USB Ethernet instead:
```nix
systemd.network.networks."10-disable-enp2s0f0" = {
  matchConfig.Name = "enp2s0f0";
  linkConfig.Unmanaged = "yes";
};
```

### Router testing

The router module (`modules/nixos/router/`) is tested via `packages/router-test/`. This allows validating router configurations without deploying to physical hardware.

### IPv6

Currently disabled on the router (`cloudberry`). TODO: enable IPv6.
Current ISP doesn't support IPv6 anyway: https://heeftodidoipv6.nl/

### Auto-cpufreq

Most bare metal hosts run auto-cpufreq with conservative settings to conserve energy.
