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
- **Interactive RAID selection** -- shows usable capacity and redundancy for each RAID level
- **Full QEMU observability** -- serial console output with real-time progress tracking
- **SSH hardening** -- auto-detects keys from rescue, disables password login (cluster-safe)
- **DHCP on NAT bridge** -- VMs get automatic connectivity via dnsmasq on vmbr1
- **First-boot hooks** -- all configuration applied on first boot (PVE 8.3+)
- **Unattended mode** -- configure via CLI arguments or `.env` files
- **ISO verification** -- SHA256 checksum validation
- **Performance tuning** -- TCP BBR, swappiness, journald limits, pigz backups, ZFS ARC
- **Enterprise logging** -- structured log levels, JSON reports
- **Hetzner-aware networking** -- `predict-check` integration, NAT/routed/bridged support
- **Self-contained bundle** -- no runtime downloads of templates or scripts

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

**One-liner** (recommended):

```bash
curl -4fsSL https://github.com/corelix-io/pve-hetzner/releases/latest/download/install.sh | bash
```

**One-liner with arguments** (fully unattended):

```bash
curl -4fsSL https://github.com/corelix-io/pve-hetzner/releases/latest/download/install.sh | bash -s -- \
    --hostname pve1 --fqdn pve1.example.com --password "YourSecurePassword" \
    --timezone UTC --email admin@example.com --unattended --yes
```

**Manual download**:

```bash
# Download latest release
wget -4 https://github.com/corelix-io/pve-hetzner/releases/latest/download/install.sh -O install.sh
bash install.sh
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
│   ├── disk.sh                 Disk discovery, RAID selection, validation
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
| 3 | Disk detection, selection, and RAID level choice | `disk.sh` |
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
SYSTEM:
  --hostname NAME        Hostname (e.g., pve1)
  --fqdn FQDN           Fully qualified domain name
  --password PASS        Root password
  --email EMAIL          Admin notification email
  --timezone TZ          Timezone (e.g., UTC, Europe/Berlin)
  --keyboard LAYOUT      Keyboard layout (default: en-us)
  --country CODE         Country code (default: us)
  --ssh-keys "KEY..."    SSH public keys (enables key-only SSH)

DISK:
  --disk-mode MODE       auto or manual (default: auto)
  --disks LIST           Comma-separated disk names (e.g., nvme0n1,nvme1n1)
  --filesystem FS        zfs, ext4, xfs, btrfs (default: zfs)
  --zfs-raid LEVEL       raid0, raid1, raid10, raidz-1/2/3 (default: raid1)
  --zfs-compress ALG     lz4, zstd, on, off (default: lz4)
  --zfs-ashift N         ZFS ashift value
  --zfs-arc-max MiB      ZFS ARC max memory in MiB

NETWORK:
  --interface NAME       Network interface override
  --private-subnet CIDR  NAT subnet (e.g., 192.168.26.0/24)
  --network-mode MODE    nat, routed, bridged (default: nat)
  --dhcp                 Enable DHCP server on NAT bridge (default)
  --no-dhcp              Disable DHCP server on NAT bridge
  --dns SERVERS          DNS servers (space-separated)

INSTALL:
  --iso PATH             Skip download, use local ISO
  --boot-mode MODE       auto, uefi, legacy (default: auto)
  --debian-suite SUITE   Debian suite (default: trixie)
  --config FILE          Load .env configuration file
  --unattended           No interactive prompts
  --yes, -y              Skip confirmation prompts
  --debug                Enable debug logging
  --quiet                Suppress info-level output
  --help, -h             Show help
  --version, -v          Show version
```

### Configuration File

Create a `.env` file (see `configs/` for examples):

```bash
# System
PVE_HOSTNAME="pve1"
PVE_FQDN="pve1.example.com"
PVE_ROOT_PASSWORD="secure-password"
PVE_TIMEZONE="UTC"
PVE_EMAIL="admin@example.com"
PVE_KEYBOARD="en-us"
PVE_COUNTRY="us"
PVE_SSH_KEYS="ssh-ed25519 AAAA... user@host"

# Disk
PVE_FILESYSTEM="zfs"
PVE_ZFS_RAID="raid1"
PVE_ZFS_COMPRESS="lz4"

# Network
PVE_PRIVATE_SUBNET="192.168.26.0/24"
PVE_NETWORK_MODE="nat"
PVE_ENABLE_DHCP=true
PVE_DNS_SERVERS="185.12.64.1 185.12.64.2"
```

### Precedence

Configuration values are merged in this order (last wins):

1. Built-in defaults (`configs/default.env`)
2. Config file (`--config`)
3. CLI arguments
4. Interactive prompts

## What Gets Configured

The installer's first-boot script applies these configurations automatically:

### Networking
- **vmbr0**: Public bridge with server's main IP (bridged to physical NIC)
- **vmbr1**: Private NAT bridge for VMs/containers with MASQUERADE
- **DHCP**: dnsmasq on vmbr1 (`.100-.200` range) so VMs get IPs automatically
- **IPv6**: Configured on both bridges when available

### SSH Security
When SSH keys are provided (auto-detected from rescue or manually entered):
- Keys installed to `/root/.ssh/authorized_keys` and `/etc/pve/priv/authorized_keys` (cluster-synced)
- `PermitRootLogin prohibit-password` (safe for Proxmox clustering)
- `PasswordAuthentication no`
- Drop-in config at `/etc/ssh/sshd_config.d/99-hardening.conf`

### Performance Tuning
- **TCP BBR** congestion control (better throughput on fast links)
- **TCP Fast Open** (reduced connection latency)
- **Swappiness = 10** (prevents aggressive swapping on hypervisors)
- **Kernel panic auto-reboot** after 10s (critical for unattended servers)
- **inotify watches** increased to 1M (fixes "no space left" with many containers)
- **Journald** limited to 64MB (prevents log bloat)
- **ZFS ARC** tuned dynamically based on RAM (5% min, 15% max)
- **nf_conntrack** tuned for NAT (1M max entries, 8h timeout)
- **pigz** installed for 2-4x faster vzdump backups
- **vzdump** bandwidth limit removed, IO priority set

### APT Repositories
- All enterprise repos disabled (PVE + Ceph, both `.list` and `.sources` formats)
- No-subscription repos added for PVE and Ceph
- Subscription nag removed with daily cron to persist across updates

## QEMU Observability

- **Serial console**: Installer output captured to `logs/qemu-install-serial.log`
- **Progress tracking**: Real-time phase detection
- **Monitor socket**: Programmatic QEMU control via `socat`
- **Timeout protection**: Auto-kills after 20 minutes
- **Failure diagnostics**: Last 20 lines of serial output shown on error

## Post-Installation Security

After reboot, **configure IP filtering before going to production**:

### Hetzner Robot Firewall (recommended)
1. Go to `robot.hetzner.com` > Server > Firewall
2. Create rules to ALLOW ports 22, 8006 only from your management IP(s)
3. Set default incoming policy to DROP
4. Apply the firewall to your server

### Proxmox Built-in Firewall (additional layer)
1. Datacenter > Firewall > Add rules for SSH/HTTPS
2. Enable at Datacenter + Node level

## Troubleshooting

See [TROUBLESHOOTING.md](.claude/docs/TROUBLESHOOTING.md) for common issues:

- Server unreachable after reboot
- Locked out after SSH hardening
- QEMU fails to start or hangs
- ZFS pool not created
- Wrong boot mode
- Hetzner firewall not blocking traffic

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
