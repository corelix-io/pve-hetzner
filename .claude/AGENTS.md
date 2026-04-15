# Proxmox Hetzner Installer -- Agent Instructions

## Project Overview

This project is an enterprise-grade automation tool for installing **Proxmox VE** on
**Hetzner dedicated servers** from the Hetzner Rescue System -- without requiring KVM
console access. It boots the official Proxmox ISO inside QEMU, writes directly to the
server's physical disks, and configures networking for the Hetzner environment.

**Branding**: "Provided freely by Corelix.io - Made in France" -- Author: Amir Moradi.
This attribution MUST be preserved in the banner, help text, reports, and README.
**License**: BSD 3-Clause with Branding Protection (see LICENSE).

## Repository Layout

```
pve-install.sh          # Main entry point / orchestrator
lib/                    # Sourced bash library modules
  logging.sh            # Structured logging with levels and timestamps
  ui.sh                 # Colors, spinners, progress bars, banners
  config.sh             # CLI arg parsing, config file loading, defaults
  validate.sh           # Input validation (IP, FQDN, password, disk, etc.)
  cleanup.sh            # Trap handlers for EXIT/INT/TERM
  hardware.sh           # CPU, RAM, boot mode detection
  disk.sh               # Disk discovery, selection, RAID validation
  network.sh            # Interface detection, IP/gateway/MAC extraction
  iso.sh                # ISO download with checksum verification
  answer.sh             # answer.toml generation (Proxmox auto-install)
  firstboot.sh          # First-boot script generation
  qemu.sh               # QEMU launch with serial console + monitor
  ssh-config.sh         # Legacy SSH-based post-install config (fallback)
  report.sh             # Final installation report
templates/              # Configuration file templates with {{PLACEHOLDER}} syntax
configs/                # Example .env configuration files
tests/                  # Validation and unit tests
docs/                   # User-facing documentation
```

## Code Style

- **Shell**: Bash 5+. All scripts begin with `#!/usr/bin/env bash` and `set -euo pipefail`.
- **Shellcheck**: All code must pass `shellcheck` with zero warnings.
- **Quoting**: Always double-quote variable expansions: `"$VAR"`, `"${ARRAY[@]}"`.
- **Functions**: Prefix with module name: `disk_detect()`, `net_get_active_interface()`.
- **Naming**: `UPPER_SNAKE` for exported/config vars, `lower_snake` for locals.
- **Comments**: Only for non-obvious logic. No narration comments.
- **Error handling**: Use `|| die "message"` for critical failures. Never silently swallow errors.
- **No external downloads at runtime**: All templates ship in-repo under `templates/`.
- **IPv4 only**: All `curl`/`wget` calls MUST use `-4` flag. Hetzner rescue has broken IPv6.
- **apt IPv4**: Set `Acquire::ForceIPv4 "true"` before any apt operations.

## Module Pattern

Each `lib/*.sh` file:
1. Has a header comment with a one-line description.
2. Exports functions prefixed with the module name (e.g., `log_info`, `ui_banner`).
3. Does NOT execute code at source time -- only function definitions.
4. Uses `local` for all function-scoped variables.
5. Returns non-zero on failure with a descriptive message to stderr.

## Template Pattern

Templates live under `templates/` and use `{{PLACEHOLDER}}` syntax. They are rendered
by `sed` substitution at install time. Rendered files go to `generated/` (gitignored).

Available placeholders must be documented at the top of each `.tpl` file.

## Key Constraints

### Hetzner Rescue System
- Runs Debian-based minimal Linux with root access.
- Network interface in rescue is always `eth0`; the real name differs post-install.
- Use `predict-check` (Hetzner tool) to discover post-reboot interface names.
- Use `netdata` (Hetzner tool) to query MAC address and link status.
- IP/MAC binding is enforced -- bridged setups require virtual MACs from Robot Panel.
- The gateway is always reachable at `fe80::1` for IPv6.

### Proxmox Auto-Install
- Uses TOML-formatted `answer.toml` with kebab-case keys (PVE 8.4+).
- ISO is prepared with `proxmox-auto-install-assistant prepare-iso`.
- First-boot hooks available since PVE 8.3 (`--on-first-boot` flag).
- Disk names inside QEMU are `/dev/vdX` (virtio), not the host `/dev/nvmeXnY`.
- The `[network] source = "from-dhcp"` works inside QEMU's user-mode networking.

### QEMU in Rescue
- Must pass physical disks as `-drive file=/dev/XXX,format=raw,if=virtio`.
- Use `-serial file:LOG` for installer output capture.
- Use `-monitor unix:SOCK,server,nowait` for programmatic control.
- UEFI requires `-bios /usr/share/OVMF/OVMF_CODE.fd` (check path on rescue).
- Resource allocation should be dynamic based on host hardware.

## Testing

- `tests/test-validate.sh` -- unit tests for validation functions.
- `tests/test-config.sh` -- config parsing and default merging.
- `tests/test-templates.sh` -- template rendering with known inputs.
- Run all: `bash tests/run-all.sh`

## Commit Messages

- Format: `type: short description` (e.g., `feat: add disk auto-detection`).
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.
- Body explains *why*, not *what*.
