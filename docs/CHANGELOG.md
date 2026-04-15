# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - 2026-04-15

### Added
- Complete rewrite with modular architecture (`lib/*.sh` modules).
- Dynamic hardware detection: CPU, RAM, disks, network interfaces, boot mode.
- Interactive RAID level selection with usable capacity and redundancy info.
- QEMU serial console output for real-time installation progress monitoring.
- QEMU monitor socket for programmatic VM control and clean shutdown.
- First-boot hook support (PVE 8.3+) eliminating the need for SSH-based config.
- CLI argument parsing with 30+ options for fully unattended deployments.
- Configuration file support (`.env` format) with example configs.
- Input validation for all user-provided values.
- ISO checksum verification (SHA256).
- Comprehensive installation report (terminal + JSON).
- Structured logging with levels (DEBUG, INFO, WARN, ERROR, FATAL).
- Branded terminal UI with progress bars, spinners, and phase tracking.
- Trap-based cleanup for QEMU processes and temporary files.
- Support for SATA, NVMe, and mixed disk configurations.
- Automatic QEMU resource allocation based on host hardware.
- `predict-check` integration for correct post-install interface naming.
- GitHub Actions workflow for building self-contained release bundles.
- One-liner bootstrap installer (`install.sh`).
- IPv4-only networking to avoid Hetzner rescue IPv6 timeout issues.
- SSH key auto-detection from rescue system authorized_keys.
- SSH hardening via first-boot: key-only auth, `PermitRootLogin prohibit-password`.
- DHCP server (dnsmasq) on NAT bridge (vmbr1) for automatic VM connectivity.
- `--dhcp` / `--no-dhcp` CLI flags and `PVE_ENABLE_DHCP` config option.
- `--ssh-keys` CLI flag and interactive SSH key prompt.
- `--keyboard`, `--country`, `--dns`, `--debian-suite` CLI options.
- `--zfs-ashift`, `--zfs-arc-max` for ZFS tuning via CLI.
- `--quiet`, `--version`, `-v`, `-y` CLI convenience flags.
- Performance tuning in first-boot:
  - TCP BBR congestion control.
  - TCP Fast Open.
  - Swappiness reduced to 10.
  - Kernel panic auto-reboot (10s).
  - inotify watches increased to 1M.
  - Journald size limited to 64M.
  - ZFS ARC dynamically tuned based on host RAM.
  - nf_conntrack tuned for NAT (1M max, 8h timeout).
  - pigz for faster vzdump backup compression.
  - vzdump bandwidth limit removed.
- Subscription nag removal with daily cron to persist across apt upgrades.
- Security advisory in install report (Hetzner firewall guidance).
- Ceph no-subscription repo alongside PVE no-subscription repo.
- Content-based enterprise repo detection (catches `ceph.sources` and future files).
- Branding: "Provided freely by Corelix.io - Made in France".
- Complete project documentation and `.claude` agent instructions.

### Changed
- Moved from single-script to modular library architecture.
- Disk paths are now auto-detected instead of hardcoded to `/dev/nvme0n1`.
- QEMU is no longer a black box (serial + monitor output).
- Templates are now shipped in-repo instead of fetched from GitHub at runtime.
- answer.toml uses kebab-case keys (PVE 8.4+ compatible).
- Network configuration uses `predict-check` for correct interface names.
- License changed from MIT to BSD 3-Clause with branding protection.
- All curl/wget calls use `-4` flag to force IPv4.
- apt configured with `Acquire::ForceIPv4 "true"` during installation.
- All `read` calls use safe `ui_read` wrapper (handles `set -e` and pipe stdin).
- All `(( var++ ))` replaced with `var=$(( var + 1 ))` to avoid `set -e` traps.
- Enterprise repo disabling handles both `.list` and `.sources` (DEB822) formats.

### Removed
- Legacy `sshpass -p` password exposure (uses `SSHPASS` env var or SSH keys).
- Hardcoded disk paths and QEMU resource values.
- Runtime template downloads from GitHub.
- Multiple redundant README files (v0, v1, v2).
- Old repo references (`ariadata/proxmox-hetzner`).

### Fixed
- Missing `qemu-system-x86_64` and `nc` in dependency installation.
- No cleanup of QEMU processes on script failure.
- Password visible in process list via `sshpass -p`.
- `set -e` without `pipefail` allowing silent pipeline failures.
- Version skew between bookworm (rescue) and trixie (install) repos.
- IPv6 timeout delays in Hetzner rescue mode for all network operations.
- `read -e` hanging when stdin is a pipe (`curl | bash`).
- `(( 0++ ))` returning exit code 1 under `set -e`.
- `[[ ]] &&` as last function statement causing silent exit under `set -e`.
- QEMU global variables lost in `$()` subshell.
- `bc` not available in Hetzner rescue (pure bash arithmetic).
- Hetzner rescue detection (multiple methods: installimage, motd, resolv.conf, hostname).
- `ceph.sources` enterprise repo not disabled (DEB822 format with non-obvious filename).
- Subscription nag returning after apt upgrades (daily cron fix).

## [1.0.0] - 2025-01-01

### Added
- Initial release with single-script automated Proxmox VE installation.
- Support for Hetzner AX/EX/SX server series.
- ZFS RAID-1 installation via QEMU in rescue mode.
- Basic network configuration templates.
