# Skill: Hetzner Rescue System Operations

## When to Use

Use when working with code that interacts with the Hetzner Rescue System environment,
including disk operations, network detection, QEMU launches, and package installation.

## Key Knowledge

### Entering Rescue Mode
1. Hetzner Robot Panel > Server > Rescue tab.
2. Select Linux 64-bit, optionally add SSH key.
3. Activate, then go to Reset tab > Execute hardware reset.
4. SSH into the rescue IP within 2-3 minutes.

### Available Tools in Rescue
- `predict-check` -- maps rescue interface names to post-boot names.
- `netdata` -- shows link status, MAC, IP, driver for each interface.
- `installimage` -- Hetzner's OS installer (not used for Proxmox ISO installs).
- Standard Linux tools: `ip`, `lsblk`, `fdisk`, `udevadm`, `modprobe`.
- QEMU/KVM is available (may need `apt install qemu-system-x86`).

### Rescue Environment Facts
- Root filesystem is in RAM (tmpfs).
- `/root` is the working directory.
- `eth0` is the active interface (always this name in rescue).
- Kernel supports KVM but modules may need loading: `modprobe kvm kvm_intel`.
- OVMF firmware at `/usr/share/OVMF/OVMF_CODE.fd` or `/usr/share/ovmf/OVMF.fd`.
- APT works but package selection is limited.

### Disk Access
- NVMe drives: `/dev/nvme0n1`, `/dev/nvme1n1`, etc.
- SATA drives: `/dev/sda`, `/dev/sdb`, etc.
- Disks may have existing partitions/data from previous OS.
- QEMU passes them as raw virtio devices.

### Network in Rescue vs Post-Install
```
Rescue:      eth0 → enp0s31f6 (after install)
             Use predict-check to discover mapping.
             
Post-install interface name is what goes into /etc/network/interfaces.
```

### Common Patterns
```bash
# Check boot mode
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"

# Predict interface name
predict-check  # Output: eth0 -> enp0s31f6

# Get network info
netdata        # Shows MAC, IP, link status

# List disks
lsblk -dpno NAME,SIZE,TYPE,TRAN | grep disk

# Load KVM
modprobe kvm && modprobe kvm_intel 2>/dev/null || modprobe kvm_amd 2>/dev/null
```
