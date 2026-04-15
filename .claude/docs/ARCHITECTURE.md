# Architecture

## Execution Flow

The installer runs in 11 sequential phases, each handled by a dedicated library module.

```
Phase  1: Preflight Checks      (hardware.sh)   -- root, rescue mode, KVM
Phase  2: Hardware Detection     (hardware.sh)   -- CPU, RAM, boot mode
Phase  3: Disk Detection         (disk.sh)       -- enumerate, select, validate RAID
Phase  4: Network Detection      (network.sh)    -- interfaces, IPs, predicted names
Phase  5: Configuration          (config.sh)     -- interactive prompts or CLI/file
Phase  6: Validation             (validate.sh)   -- verify all inputs
Phase  7: Dependencies           (iso.sh)        -- apt install required packages
Phase  8: ISO Acquisition        (iso.sh)        -- download + verify checksum
Phase  9: Config Generation      (answer.sh,     -- answer.toml, first-boot.sh,
                                  firstboot.sh)     network templates
Phase 10: Installation           (qemu.sh)       -- QEMU with serial console
Phase 11: Report                 (report.sh)     -- summary + next steps
```

## Module Dependency Graph

```
pve-install.sh
  ├── lib/logging.sh       (no dependencies)
  ├── lib/ui.sh            (depends on: logging.sh)
  ├── lib/config.sh        (depends on: logging.sh, ui.sh)
  ├── lib/validate.sh      (depends on: logging.sh)
  ├── lib/cleanup.sh       (depends on: logging.sh, ui.sh)
  ├── lib/hardware.sh      (depends on: logging.sh, ui.sh)
  ├── lib/disk.sh          (depends on: logging.sh, ui.sh, validate.sh)
  ├── lib/network.sh       (depends on: logging.sh, ui.sh, validate.sh)
  ├── lib/iso.sh           (depends on: logging.sh, ui.sh)
  ├── lib/answer.sh        (depends on: logging.sh, config.sh)
  ├── lib/firstboot.sh     (depends on: logging.sh, config.sh)
  ├── lib/qemu.sh          (depends on: logging.sh, ui.sh, cleanup.sh, disk.sh, hardware.sh)
  ├── lib/ssh-config.sh    (depends on: logging.sh, ui.sh, cleanup.sh)
  └── lib/report.sh        (depends on: logging.sh, ui.sh)
```

## Data Flow

```
User Input / Config File / CLI Args
         │
         ▼
   ┌─────────────┐
   │  config.sh   │  Merges: defaults → config file → CLI args → interactive
   └──────┬──────┘
          │  PVE_* environment variables
          ▼
   ┌─────────────┐     ┌─────────────┐
   │ validate.sh  │────▶│  answer.sh   │──▶ generated/answer.toml
   └──────┬──────┘     └─────────────┘
          │                    │
          │              ┌─────────────┐
          │              │ firstboot.sh │──▶ generated/first-boot.sh
          │              └─────────────┘
          │                    │
          ▼                    ▼
   ┌─────────────┐     ┌─────────────┐
   │   iso.sh     │────▶│   qemu.sh   │──▶ Install to physical disks
   └─────────────┘     └──────┬──────┘
                              │
                              ▼
                       ┌─────────────┐
                       │  report.sh   │──▶ Terminal + log file
                       └─────────────┘
```

## Configuration Precedence (lowest to highest)

1. Built-in defaults (`configs/default.env`)
2. Config file (`--config path/to/file.env`)
3. CLI arguments (`--hostname`, `--fqdn`, etc.)
4. Interactive prompts (only in interactive mode)

## Directory Conventions

| Directory     | Purpose                        | Git-tracked |
|---------------|--------------------------------|-------------|
| `lib/`        | Bash library modules           | Yes         |
| `templates/`  | Config file templates          | Yes         |
| `configs/`    | Example configuration files    | Yes         |
| `tests/`      | Test scripts                   | Yes         |
| `docs/`       | User documentation             | Yes         |
| `generated/`  | Rendered configs (runtime)     | No          |
| `logs/`       | Install logs (runtime)         | No          |
