# Troubleshooting Guide

## Server Unreachable After Reboot

**Symptom:** Server does not respond to ping or SSH after exiting rescue mode.

**Cause:** Incorrect network interface name in `/etc/network/interfaces`.

**Fix:**
1. Reboot into rescue mode from Hetzner Robot Panel.
2. Mount the root filesystem: `mount /dev/nvme0n1p2 /mnt` (adjust partition).
3. For ZFS: `zpool import -f rpool && mount -t zfs rpool/ROOT/pve-1 /mnt`.
4. Check the configured interface: `cat /mnt/etc/network/interfaces`.
5. Compare with predicted name: `predict-check`.
6. Fix the interface name, unmount, and reboot.

## QEMU Fails to Start

**Symptom:** `qemu-system-x86_64: ... KVM not available`

**Cause:** KVM kernel module not loaded in rescue system.

**Fix:**
```bash
modprobe kvm
modprobe kvm_intel  # or kvm_amd
```

If modules are not available, the rescue kernel may not support KVM. Contact
Hetzner support or try a different rescue OS version.

## QEMU Hangs During Installation

**Symptom:** Serial log shows no output for > 10 minutes.

**Possible causes:**
1. Insufficient RAM allocated to QEMU (minimum 4GB recommended).
2. Disk errors on one of the target drives.
3. answer.toml has invalid configuration.

**Fix:**
1. Check serial log: `tail -f logs/qemu-install-serial.log`.
2. Use QEMU monitor: `echo info status | socat - UNIX-CONNECT:/tmp/qemu-monitor-*.sock` (find actual path with `ls /tmp/qemu-monitor-*.sock`).
3. Kill and retry with more RAM: `kill $QEMU_PID`.

## ISO Download Fails

**Symptom:** `wget` returns 404 or connection timeout.

**Cause:** Proxmox ISO URL changed or enterprise.proxmox.com is down.

**Fix:**
1. Download ISO manually and place as `pve.iso` in the working directory.
2. Use `--iso /path/to/pve.iso` flag to skip download.
3. Check current ISOs at: https://enterprise.proxmox.com/iso/

## ZFS Pool Not Created

**Symptom:** Installation completes but no ZFS pool exists.

**Cause:** Disk mismatch between `answer.toml` disk-list and actual devices.

**Fix:** Ensure `disk-list` uses virtio names (`vda`, `vdb`) when installing via
QEMU, not the host device names (`nvme0n1`).

## SSH Connection Refused (Legacy Fallback)

**Symptom:** Port 5555 never becomes available during SSH config phase.

**Possible causes:**
1. QEMU failed to boot the installed system.
2. SSH is not enabled on the installed Proxmox.
3. Password authentication is disabled.

**Fix:**
1. Check QEMU log: `cat logs/qemu-config.log`.
2. Verify QEMU process is running: `ps aux | grep qemu`.
3. Ensure the boot disk has a valid installation.

## Wrong Boot Mode (UEFI vs Legacy)

**Symptom:** System installs but fails to boot.

**Cause:** Mismatch between rescue system boot mode and QEMU configuration.

**Detection:**
```bash
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "Legacy BIOS"
```

**Fix:** The installer auto-detects boot mode. If detection fails, use
`--boot-mode uefi` or `--boot-mode legacy` to override.

## Subscription Nag Still Shows

**Symptom:** Proxmox web UI shows "No valid subscription" popup.

**Cause:** First-boot script did not run or failed silently.

**Fix:**
```bash
sed -Ezi.bak \
    "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" \
    /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy.service
```

## Locked Out After SSH Hardening

**Symptom:** Cannot SSH into the server after reboot. `Permission denied (publickey)`.

**Cause:** SSH password authentication was disabled but your key is missing or
incorrect on the server.

**Fix:**
1. Reboot into Hetzner rescue mode (Robot Panel > Rescue > Reset).
2. Mount the root filesystem:
   - ZFS: `zpool import -f rpool && mount -t zfs rpool/ROOT/pve-1 /mnt`
   - ext4: `mount /dev/sda2 /mnt`
3. Add your public key:
```bash
mkdir -p /mnt/root/.ssh
echo "ssh-ed25519 AAAA... you@host" >> /mnt/root/.ssh/authorized_keys
chmod 600 /mnt/root/.ssh/authorized_keys
```
4. Or re-enable password login temporarily:
```bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' \
    /mnt/etc/ssh/sshd_config.d/99-hardening.conf
```
5. Unmount and reboot: `umount /mnt && reboot` (or `zpool export rpool && reboot`).

**Prevention:** Always verify your SSH key works from a second terminal
before closing your current session after hardening SSH.

## IPv6 Not Working

**Symptom:** IPv6 addresses assigned but no connectivity.

**Cause:** IPv6 forwarding not enabled or wrong gateway.

**Fix:**
1. Ensure `net.ipv6.conf.all.forwarding=1` in sysctl.
2. Hetzner IPv6 gateway is always `fe80::1`.
3. Use `/128` on the main interface, `/64` on the bridge.

## Hetzner Firewall Not Blocking Traffic

**Symptom:** Ports 22 and 8006 are accessible from any IP despite setting up rules.

**Cause:** Hetzner Robot firewall is not applied, or rules are misconfigured.

**Fix:**
1. Go to Robot Panel > Server > Firewall.
2. Verify the firewall is **activated** (green toggle).
3. Ensure default incoming policy is **DROP** (not ACCEPT).
4. Rules should explicitly ALLOW ports 22, 8006 only from your management IPs.
5. The Hetzner firewall operates at the network edge -- it filters before traffic
   reaches your server. This is the most effective layer for Hetzner deployments.
