# Proxmox VE Automated Installation Reference

## Overview

Since PVE 8.2, Proxmox supports unattended installation via an `answer.toml` file.
The `proxmox-auto-install-assistant` tool prepares ISOs for automated deployment.

## Answer File Format (TOML)

All keys use **kebab-case** (PVE 8.4+). Legacy `snake_case` is deprecated.

### Complete Schema

```toml
[global]
keyboard = "en-us"                    # de, en-gb, en-us, fr, etc.
country = "us"                        # Two-letter country code
fqdn = "pve.example.com"             # Or use fqdn.source / fqdn.domain
mailto = "admin@example.com"
timezone = "UTC"
root-password = "plaintext"           # Or use root-password-hashed
# root-password-hashed = "$y$..."     # yescrypt hash (one of the two required)
root-ssh-keys = [                     # Optional
    "ssh-ed25519 AAAA..."
]
reboot-on-error = false               # Drop to shell on failure (for debugging)

[network]
source = "from-dhcp"                  # "from-dhcp" or "from-answer"
# When source = "from-answer":
# cidr = "10.0.0.10/24"
# dns = "10.0.0.1"
# gateway = "10.0.0.1"
# filter.ID_NET_NAME = "enp*"        # UDEV property filter

[network.interface-name-pinning]      # Optional, PVE 9.1+
enabled = true
[network.interface-name-pinning.mapping]
"aa:bb:cc:dd:ee:ff" = "lan0"

[disk-setup]
filesystem = "zfs"                    # ext4, xfs, zfs, btrfs (PVE only)
# Use EITHER disk-list OR filter, not both:
disk-list = ["vda", "vdb"]            # Disk names (as seen by installer)
# filter.ID_SERIAL = "Samsung*"       # UDEV property filter
# filter-match = "any"                # "any" (default) or "all"

# ZFS-specific options:
zfs.raid = "raid1"                    # raid0, raid1, raid10, raidz-1/2/3
# zfs.ashift = 12                     # Sector size shift
# zfs.arc-max = 4096                  # Max ARC in MiB
# zfs.compress = "lz4"                # on, off, lz4, zstd, etc.
# zfs.checksum = "on"                 # on, fletcher4, sha256
# zfs.hdsize = 150                    # GB to use per disk

# LVM-specific (ext4/xfs):
# lvm.hdsize = 100
# lvm.swapsize = 8
# lvm.maxroot = 50
# lvm.maxvz = 0
# lvm.minfree = 10

[post-installation-webhook]           # Optional, PVE 8.3+
url = "https://my.endpoint/postinst"
cert-fingerprint = "AA:E8:..."        # Optional TLS pinning

[first-boot]                          # Optional, PVE 8.3+
source = "from-iso"                   # "from-iso" or "from-url"
ordering = "fully-up"                 # "before-network", "network-online", "fully-up"
# url = "https://..."                  # When source = "from-url"
# cert-fingerprint = "AA:..."         # Optional TLS pinning
```

## ISO Preparation

### Embed answer in ISO
```bash
proxmox-auto-install-assistant prepare-iso pve.iso \
    --fetch-from iso \
    --answer-file answer.toml \
    --output pve-autoinstall.iso
```

### With first-boot hook
```bash
proxmox-auto-install-assistant prepare-iso pve.iso \
    --fetch-from iso \
    --answer-file answer.toml \
    --on-first-boot first-boot.sh \
    --output pve-autoinstall.iso
```

### Validate answer file
```bash
proxmox-auto-install-assistant validate-answer answer.toml
```

### Query device info (for filters)
```bash
proxmox-auto-install-assistant device-info -t disk
proxmox-auto-install-assistant device-info -t network
proxmox-auto-install-assistant device-match disk ID_SERIAL='Samsung*'
```

## QEMU Disk Mapping

When installing via QEMU, physical disks appear as virtio devices:

| Host Device     | QEMU Argument                                        | Guest Device |
|-----------------|------------------------------------------------------|--------------|
| `/dev/nvme0n1`  | `-drive file=/dev/nvme0n1,format=raw,if=virtio`      | `/dev/vda`   |
| `/dev/nvme1n1`  | `-drive file=/dev/nvme1n1,format=raw,if=virtio`      | `/dev/vdb`   |
| `/dev/sda`      | `-drive file=/dev/sda,format=raw,if=virtio`           | `/dev/vda`   |

The `disk-list` in `answer.toml` must use **guest device names** (`vda`, `vdb`).

## Version Compatibility

| Feature                    | Minimum Version |
|----------------------------|-----------------|
| Automated installation     | PVE 8.2-1       |
| Post-install webhook       | PVE 8.3-1       |
| First-boot hooks           | PVE 8.3-1       |
| `root-password-hashed`     | PVE 8.3-1       |
| `fqdn.source` sub-options  | PVE 8.4-1       |
| `reboot-mode` option       | PVE 8.4-1       |
| kebab-case keys            | PVE 8.4-1       |
| Interface name pinning     | PVE 9.1-1       |
| Deprecated snake_case      | PVE 9.0-1       |

## Troubleshooting Logs

If automated install fails, check (inside the installer environment):
- `/tmp/fetch_answer.log` -- answer file retrieval
- `/tmp/auto_installer` -- answer parsing, hardware matching
- `/tmp/install-low-level-start-session.log` -- actual installation
