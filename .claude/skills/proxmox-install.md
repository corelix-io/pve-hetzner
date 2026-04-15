# Skill: Proxmox VE Installation Patterns

## When to Use

Use when working with Proxmox VE automated installation, answer.toml generation,
QEMU-based installs, or first-boot hook scripts.

## QEMU Installation Pattern

### Serial Console for Observability
The Proxmox installer outputs progress to serial console. Capture it:

```bash
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp "$CPUS" -m "${RAM_MB}" \
    -boot d -cdrom pve-autoinstall.iso \
    -drive file=/dev/nvme0n1,format=raw,if=virtio \
    -serial file:serial.log \
    -monitor unix:/tmp/qemu-mon.sock,server,nowait \
    -no-reboot \
    -display none
```

### Progress Milestones in Serial Log
The Proxmox installer emits recognizable output to serial. Key patterns:
- `starting installation` -- installer has begun
- `Performing auto-installation` -- answer.toml accepted
- `Creating filesystem` or `creating zpool` -- disk setup
- `Installing base system` -- debootstrap phase
- `Configuring` or `Running post-installation` -- near completion
- `Installation successful` -- done, QEMU will exit due to `-no-reboot`

### Monitor Socket Commands
The monitor socket path includes the PID: `/tmp/qemu-monitor-$$.sock`.
Find it with `ls /tmp/qemu-monitor-*.sock`.

```bash
SOCK=$(ls /tmp/qemu-monitor-*.sock 2>/dev/null | head -1)

# Check VM status
echo "info status" | socat - UNIX-CONNECT:$SOCK

# Force quit
echo "quit" | socat - UNIX-CONNECT:$SOCK

# Send key combination (e.g., Ctrl+Alt+Del)
echo "sendkey ctrl-alt-delete" | socat - UNIX-CONNECT:$SOCK
```

## answer.toml Best Practices

### For Hetzner QEMU Installs
```toml
[global]
keyboard = "en-us"
country = "us"
fqdn = "pve.example.com"
mailto = "admin@example.com"
timezone = "UTC"
root-password = "changeme"
reboot-on-error = false

[network]
source = "from-dhcp"

[disk-setup]
filesystem = "zfs"
zfs.raid = "raid1"
zfs.compress = "lz4"
disk-list = ["vda", "vdb"]
```

Key points:
- `source = "from-dhcp"` works with QEMU user-mode networking.
- Disk names are `vda`/`vdb` (virtio), NOT the host `/dev/nvmeXnY`.
- `reboot-on-error = false` allows debugging failed installs.
- Set `zfs.compress = "lz4"` for better performance.

### First-Boot Hook Script
```bash
#!/bin/bash
# This runs on first boot of the installed Proxmox system.
# Ordering: "fully-up" means Proxmox APIs are available.

# Configure network (interface name is the REAL one, not eth0)
cat > /etc/network/interfaces <<'IFACES'
auto lo
iface lo inet loopback
...
IFACES

# Set hostname
hostnamectl set-hostname "myhostname"

# Restart networking
systemctl restart networking
```

Embed into ISO:
```bash
proxmox-auto-install-assistant prepare-iso pve.iso \
    --fetch-from iso \
    --answer-file answer.toml \
    --on-first-boot first-boot.sh \
    --output pve-autoinstall.iso
```

## Post-Install Verification

After rebooting from rescue to installed Proxmox:
1. SSH should work on port 22.
2. Web UI at `https://<IP>:8006`.
3. Check ZFS: `zpool status`.
4. Check network: `ip addr show`, `ip route show`.
5. Check services: `systemctl status pveproxy pvedaemon`.
