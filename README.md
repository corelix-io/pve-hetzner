# Proxmox VE Installer for Hetzner Dedicated Servers

<div align="center">

```
   ██████╗ ██╗   ██╗███████╗    ██╗  ██╗███████╗████████╗
   ██╔══██╗██║   ██║██╔════╝    ██║  ██║██╔════╝╚══██╔══╝
   ██████╔╝██║   ██║█████╗      ███████║█████╗     ██║
   ██╔═══╝ ╚██╗ ██╔╝██╔══╝      ██╔══██║██╔══╝     ██║
   ██║      ╚████╔╝ ███████╗    ██║  ██║███████╗   ██║
   ╚═╝       ╚═══╝  ╚══════╝    ╚═╝  ╚═╝╚══════╝   ╚═╝
```

**Enterprise-grade automated Proxmox VE installation on Hetzner bare metal**

*Provided freely by [Corelix.io](https://corelix.io) - Made in France*

*Author: Amir Moradi*

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)
![Shell](https://img.shields.io/badge/Shell-Bash%205%2B-green)
![Proxmox](https://img.shields.io/badge/Proxmox-8.2%2B-orange)

</div>

## Overview

This tool automates the installation of **Proxmox VE** on **Hetzner dedicated servers** directly from the Hetzner Rescue System -- no KVM console access required. It boots the official Proxmox ISO inside QEMU, writes to your server's physical disks, and configures networking for the Hetzner environment.

### Key Features

- **One-liner install** -- download, extract, and run in a single command
- **IPv4-only networking** -- avoids the IPv6 timeout issues in Hetzner rescue mode
- **Dynamic hardware detection** -- auto-discovers disks, network interfaces, CPU, RAM, and boot mode
- **Full QEMU observability** -- serial console output with real-time progress tracking (no more black-box installs)
- **Unattended mode** -- configure via CLI arguments or `.env` files for automation pipelines
- **First-boot hooks** -- network and system configuration applied on first boot (PVE 8.3+), eliminating fragile SSH-based post-install
- **ISO verification** -- SHA256 checksum validation of downloaded ISOs
- **Enterprise logging** -- structured log levels, timestamped entries, JSON reports
- **Clean error handling** -- trap-based QEMU cleanup, input validation, graceful shutdown
- **Hetzner-aware networking** -- `predict-check` integration, NAT/routed/bridged support
- **Self-contained bundle** -- no runtime downloads of templates or scripts (only the Proxmox ISO)

### Compatible Servers

| Series | Examples | Tested |
|--------|----------|--------|
| [AX Series](https://www.hetzner.com/dedicated-rootserver/matrix-ax) | AX-52, AX-102, AX-162 | Yes |
| [EX Series](https://www.hetzner.com/dedicated-rootserver/matrix-ex) | EX-44, EX-101 | Yes |
| [SX Series](https://www.hetzner.com/dedicated-rootserver/matrix-sx) | SX-64, SX-134 | Yes |

## Quick Start

### 1. Prepare Rescue Mode

1. Go to [Hetzner Robot Panel](https://robot.hetzner.com) for your server.
2. Navigate to **Rescue** tab > select **Linux 64-bit** > **Activate rescue system**.
3. Go to **Reset** tab > check **Execute an automatic hardware reset** > **Send**.
4. Wait ~2 minutes, then SSH into the rescue system.

### 2. Run the Installer

**One-liner** (recommended -- downloads the latest release bundle):

```bash
curl -4fsSL https://github.com/corelix-io/pve-hetzner/releases/latest/download/install.sh | bash
```

**One-liner with arguments** (fully unattended):

```bash
curl -4fsSL https://github.com/corelix-io/pve-hetzner/releases/latest/download/install.sh | bash -s -- \
    --hostname pve1 --fqdn pve1.example.com --password "YourSecurePassword" \
    --timezone UTC --email admin@example.com --unattended --yes
```

**Manual download** (if you prefer):

```bash
# Download latest release
wget -4 https://github.com/corelix-io/pve-hetzner/releases/latest/download/pve-hetzner-v2.0.0.tar.gz
tar xzf pve-hetzner-*.tar.gz
cd pve-hetzner-*/

# Interactive
./pve-install.sh

# Or with a config file
./pve-install.sh --config configs/example-ax102.env --unattended --yes
```

### 3. Access Proxmox

After reboot:
- **Web UI**: `https://YOUR-SERVER-IP:8006`
- **SSH**: `ssh root@YOUR-SERVER-IP`
- **Login**: `root` with the password you set during installation

## Architecture

```
pve-install.sh                  Main orchestrator (11 phases)
├── lib/
│   ├── logging.sh              Structured logging with levels
│   ├── ui.sh                   Colors, spinners, progress bars
│   ├── config.sh               CLI parsing, config files, defaults
│   ├── validate.sh             Input validation
│   ├── cleanup.sh              Trap handlers, process cleanup
│   ├── hardware.sh             CPU, RAM, boot mode detection
│   ├── disk.sh                 Disk discovery and RAID validation
│   ├── network.sh              Interface detection, IP extraction
│   ├── iso.sh                  ISO download and verification
│   ├── answer.sh               answer.toml generation
│   ├── firstboot.sh            First-boot script generation
│   ├── qemu.sh                 QEMU with serial console + monitor
│   ├── ssh-config.sh           Legacy SSH-based config (fallback)
│   └── report.sh               Installation report generation
├── templates/                  Configuration templates
├── configs/                    Example .env configuration files
└── docs/                       Documentation
```

### Installation Phases

| Phase | Description | Module |
|-------|-------------|--------|
| 1 | Preflight checks (root, rescue, KVM) | `hardware.sh` |
| 2 | Hardware detection (CPU, RAM, boot mode) | `hardware.sh` |
| 3 | Disk detection and selection | `disk.sh` |
| 4 | Network interface detection | `network.sh` |
| 5 | Configuration (interactive or unattended) | `config.sh` |
| 6 | Input validation | `validate.sh` |
| 7 | Dependency installation | `iso.sh` |
| 8 | ISO download with verification | `iso.sh` |
| 9 | Generate answer.toml + first-boot script | `answer.sh`, `firstboot.sh` |
| 10 | QEMU installation with progress monitoring | `qemu.sh` |
| 11 | Installation report and reboot prompt | `report.sh` |

## Configuration Reference

### CLI Options

```
--hostname NAME        Hostname (e.g., pve1)
--fqdn FQDN           Fully qualified domain name
--password PASS        Root password
--email EMAIL          Admin notification email
--timezone TZ          Timezone (e.g., UTC, Europe/Berlin)
--private-subnet CIDR  NAT subnet (e.g., 192.168.26.0/24)
--interface NAME       Network interface override
--disk-mode MODE       auto or manual
--disks LIST           Comma-separated disk names
--filesystem FS        zfs, ext4, xfs, btrfs
--zfs-raid LEVEL       raid0, raid1, raid10, raidz-1/2/3
--zfs-compress ALG     lz4, zstd, on, off
--iso PATH             Skip download, use local ISO
--boot-mode MODE       auto, uefi, legacy
--network-mode MODE    nat, routed, bridged
--config FILE          Load .env configuration file
--unattended           No interactive prompts
--yes                  Skip confirmation
--debug                Enable debug logging
--help                 Show full help
```

### Configuration File Format

Create a `.env` file (see `configs/` for examples):

```bash
PVE_HOSTNAME="pve1"
PVE_FQDN="pve1.example.com"
PVE_ROOT_PASSWORD="secure-password"
PVE_TIMEZONE="UTC"
PVE_EMAIL="admin@example.com"
PVE_FILESYSTEM="zfs"
PVE_ZFS_RAID="raid1"
PVE_PRIVATE_SUBNET="192.168.26.0/24"
```

### Precedence

Configuration values are merged in this order (last wins):

1. Built-in defaults (`configs/default.env`)
2. Config file (`--config`)
3. CLI arguments
4. Interactive prompts

## IPv4-Only Networking

Hetzner's rescue system has unreliable IPv6 connectivity, which causes tools like `curl`, `wget`, and `apt` to attempt IPv6 first with long timeouts before falling back to IPv4. This installer forces IPv4 for all network operations:

- `curl -4` and `wget -4` for all HTTP requests
- `Acquire::ForceIPv4 "true"` for apt package manager
- The release bundle is self-contained, so template files are never fetched at runtime

## QEMU Observability

Unlike other installers that run QEMU as a black box, this tool provides full visibility:

- **Serial console**: Proxmox installer output is captured to `logs/qemu-install-serial.log`
- **Progress tracking**: Real-time phase detection (filesystem creation, package installation, etc.)
- **Monitor socket**: Programmatic QEMU control via `socat`
- **Timeout protection**: Auto-kills hung installations after 20 minutes
- **Failure diagnostics**: Last 20 lines of serial output shown on error

## Network Configuration

The installer supports three networking modes for Hetzner:

### NAT/Masquerading (Default)
- `vmbr0`: Public bridge with server's main IP
- `vmbr1`: Private NAT bridge for VMs/containers
- Best for single-IP servers, no additional IPs needed

### Routed
- Direct routing with `/32` addresses per VM
- Requires additional IPs from Hetzner

### Bridged
- Transparent bridge mode
- Requires virtual MAC addresses from Hetzner Robot Panel

## Post-Installation

After rebooting into Proxmox:

```bash
# Update system
apt update && apt -y upgrade

# Install useful tools
apt install -y curl libguestfs-tools unzip iptables-persistent net-tools

# Configure ZFS memory limits (recommended for 64GB+ RAM)
echo "options zfs zfs_arc_min=$[6 * 1024*1024*1024]" >> /etc/modprobe.d/99-zfs.conf
echo "options zfs zfs_arc_max=$[12 * 1024*1024*1024]" >> /etc/modprobe.d/99-zfs.conf
update-initramfs -u
```

## Troubleshooting

See [TROUBLESHOOTING.md](.claude/docs/TROUBLESHOOTING.md) for common issues:

- Server unreachable after reboot
- QEMU fails to start
- Installation hangs
- ZFS pool not created
- Wrong boot mode

## Documentation

- [Changelog](docs/CHANGELOG.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Architecture](.claude/docs/ARCHITECTURE.md)
- [Hetzner Networking Reference](.claude/docs/HETZNER-NETWORKING.md)
- [Proxmox Auto-Install Reference](.claude/docs/PROXMOX-AUTOINSTALL.md)
- [Troubleshooting](.claude/docs/TROUBLESHOOTING.md)

## License

[BSD 3-Clause with Branding Protection](LICENSE)

Copyright (c) 2025-2026, Amir Moradi / Corelix.io. Free to use, including commercially. Derivative works must retain the original attribution and may not reuse the project name or branding.

---

<div align="center">
<i>Provided freely by <a href="https://corelix.io">Corelix.io</a> - Made in France</i>
</div>
