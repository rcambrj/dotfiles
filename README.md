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
| `cloudberry` | Router / gateway | x86_64 | TOPTON 4-port, handles routing, WAN failover, VPN |
| `cranberry` | Kubernetes + Gluster node | x86_64 | |
| `elderberry` | 3D printer | x86_64 | Dell Wyse 3040, runs Klipper + Fluidd |
| `lemon` | NetBird management | x86_64 | Self-hosted NetBird coordination server |
| `orange` | Kubernetes + Gluster node | x86_64 | Off-site location, connected via NetBird |

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

## Home Manager Configurations (`modules/home/`)

Portable Home Manager configurations for user environments:

- **`rcambrj-console/`** - Portable configuration for workstations and servers (shell, git, SSH, VS Code settings). Somewhat bloated for server use. Consumed by [MacBook](https://github.com/rcambrj/nix-macbook).
- **`rcambrj-graphical/`** - Graphical interface configuration (originally built for `mango`). Includes GNOME, touchpad settings, brightness controls.
- **`vscode/`** - VS Code editor configuration. Consumed by both `rcambrj-graphical` and [MacBook](https://github.com/rcambrj/nix-macbook).

## NixOS Modules (`modules/nixos/`)

Reusable NixOS modules that compose the infrastructure.

### Core Modules

| Module | Purpose |
|--------|---------|
| `base.nix` | Base system configuration (users, groups, basic services) |
| `common.nix` | Common settings shared across hosts |
| `bare-metal.nix` | Bare metal provisioning (bootloader, firmware) |
| `cloud-vps.nix` | Cloud/VPS-specific configuration |

### Hardware Configurations

| Module | Purpose |
|--------|---------|
| `config-intel.nix` | Intel hardware configuration |
| `config-raspi.nix` | Raspberry Pi configuration |
| `gpu-intel.nix` | Intel GPU support (VA-API, etc.) |

### Storage & Disk Management

| Module | Purpose |
|--------|---------|
| `disko-node.nix` | Disk partitioning for Kubernetes/Gluster nodes |
| `disko-standard.nix` | Standard disk partitioning scheme |
| `disk-savers.nix` | Workaround to reduce etcd disk wear |
| `storage.nix` | GlusterFS distributed storage setup |
| `grow-partition.nix` | A better grow-partition than nixpkgs |

### Networking

| Module | Purpose |
|--------|---------|
| `router/` | **Full router stack** - bridging, VLANs, routing, dual WAN failover, SQM, DNS (dnsmasq), firewall, UPnP, PPPoE. Tested via `packages/router-test`. |
| `netbird.nix` | NetBird VPN client configuration |
| `primary-wan.nix` | systemd service intended to _bring down_ other services when backup WAN is active |
| `up-or-down.nix` | Up/down monitoring with hysteria prevention |

### Kubernetes

| Module | Purpose |
|--------|---------|
| `kubernetes-node.nix` | Kubernetes node setup (k3s, CNI, etc.) |
| `kubernetes-manifests/` | Kubernetes manifests deployed via ArgoCD (MetalLB, etc.) |

### Backups & Monitoring

| Module | Purpose |
|--------|---------|
| `server-backup.nix` | Restic backups to S3-compatible storage |
| `telemetry.nix` | System telemetry and monitoring |

### Access Control

| Module | Purpose |
|--------|---------|
| `access-server.nix` | Server access configuration (SSH, sudo) |
| `access-workstation.nix` | Workstation access configuration |
| `root-keys.nix` | SSH authorized_keys helper |

## Kubernetes Applications (`kubernetes/`)

All Kubernetes applications are managed via ArgoCD (GitOps). Organized by function:

### Infrastructure

| Application | Purpose |
|-------------|---------|
| `bootstrap/` | Initial cluster bootstrap (applications, values) |
| `reloader/` | Automatic reload of pods when ConfigMaps/Secrets change |
| `priorities/` | PriorityClass definitions for workload scheduling |
| `utils/` | Utility scripts (ArgoCD sync helper) |

### Networking

| Application | Purpose |
|-------------|---------|
| `traefik/` | Ingress controller with Cloudflare tunnel integration |
| `descheduler/` | Kubernetes descheduler for workload rebalancing |
| `node-feature-discovery/` | Node tagging with hardware features |
| `generic-device-plugin/` | Node hardware resources (zigbee) |
| `intel-gpu/` | Node hardware resources (Intel GPU) |

### Authentication

| Application | Purpose |
|-------------|---------|
| `auth/` | Authentication stack (dex, lldap, oauth2-proxy) |

### Storage

| Application | Purpose |
|-------------|---------|
| `postgres/` | CloudNative PostgreSQL with automated backups |
| `gluster-mount-watcher/` | Monitor and recover GlusterFS mounts |

### Monitoring

| Application | Purpose |
|-------------|---------|
| `monitoring/` | kube-prometheus-stack (Prometheus, Grafana, Alertmanager) |

### Home Automation

| Application | Purpose |
|-------------|---------|
| `home-assistant/` | Home Assistant instance |
| `esphome/` | ESPHome for IoT device management |

### Media Stack

| Application | Purpose |
|-------------|---------|
| `media/` | Media services (Jellyfin, Radarr, Sonarr, transmission, etc.) |

### Other Applications

| Application | Purpose |
|-------------|---------|
| `cert-manager/` | TLS certificate management (with LDAP integration) |
| `copyparty/` | File management |
| `fdm/` | Proxy for 3D (FDM) printer web interface |
| `landing/` | Landing page / placeholder site |

## Packages (`packages/`)

Custom packages and reusable configurations:

| Package | Purpose | Reusable? |
|---------|---------|-----------|
| `fluidd-config.nix` | Klipper 3D printer web interface configuration | ✅ Reusable |
| `home-assistant-config/` | Modules include `core.nix`, `auth.nix`, `lights-and-switches.nix`, `lovelace.nix`, etc. | ❌ Highly specific |
| `mobileraker-companion.nix` | Moonraker companion for Mobileraker mobile app | ✅ Reusable |
| `router-test/` | Router testing environment for validating router module | ⚠️ Internal use |

> The `home-assistant-config/` directory demonstrates using the Nix module system to generate YAML configuration files. Each module defines options that contribute to `configuration.yaml` or `ui-lovelace.yaml`. The derivation uses `pkgs.formats.yaml` and post-processes output to support Home Assistant YAML features (secrets, includes). It's converted to YAML at pod startup in a kubernetes initContainer.

## Secrets Management

All secrets are encrypted using **agenix** with **agenix-template** for templating. Secrets are stored in `secrets/` and defined in `secrets.nix`, which maps each encrypted file to the SSH public keys that can decrypt it. Machine-specific secrets follow the pattern `{hostname}-{service}.age`.

## Quick Start

### Prerequisites

- Nix with flakes enabled
- agenix installed
- Age key pair for decrypting secrets
- Access to SSH keys listed in `lib/ssh-keys.nix`

### Building a configuration

```bash
# Check flake validity
nix flake check

# Build a host configuration
nix build .#nixosConfigurations.blueberry.config.system.build.toplevel

# Build and run a VM (if available)
nix run .#nixosConfigurations.blueberry.config.system.build.vm
```

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

#### Method 1: Headless with split USB storage (requires two USB sticks)

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

#### Method 2: Headless with AIO disk (single USB stick)

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

### Editing secrets

```bash
# Edit an age-encrypted secret
make edit-secret name=secret-name

# Or more directly:
agenix -e secrets/secret-name.age
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make clean` | Remove build results (`result` symlink) |
| `make check` | Validate flake (show outputs + run checks) |
| `make build-image machine=NAME` | Build NixOS image for specified machine |
| `make edit-secret name=NAME` | Edit age-encrypted secret |
| `make remote-switch machine=NAME` | Deploy to remote host |

## Checks & Validation

```bash
# Show flake outputs
nix flake show

# Run all checks
nix flake check

# Run specific check (e.g., router test)
nix build .#checks.x86_64-linux.router
```

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

### GlusterFS notes

- Use `*.cambridge.netbird` for cloud servers (CNAME resolution issues)
- TLS required for cross-network communication
- Replica 3 with arbiter for off-site node

### Router testing

The router module (`modules/nixos/router/`) is tested via `packages/router-test/`. This allows validating router configurations without deploying to physical hardware.

### IPv6

Currently disabled on the router (`cloudberry`). TODO: enable IPv6.
Current ISP doesn't support IPv6 anyway: https://heeftodidoipv6.nl/

### Auto-cpufreq

Most hosts run auto-cpufreq with conservative settings:
```nix
services.auto-cpufreq = {
  enable = true;
  settings.charger = {
    governor = "powersave";
    turbo = "never";
  };
};
```
