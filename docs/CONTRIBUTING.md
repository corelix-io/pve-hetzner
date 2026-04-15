# Contributing

Contributions are welcome! This document explains how to contribute effectively.

## Getting Started

1. Fork the repository.
2. Create a feature branch: `git checkout -b feat/my-feature`.
3. Make your changes following the code style guidelines below.
4. Test your changes (see Testing section).
5. Commit with a clear message: `feat: add disk filter support`.
6. Open a pull request with a description of what and why.

## Code Style

### Bash Standards
- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- All code must pass `shellcheck` with zero warnings.
- Always double-quote variable expansions: `"$VAR"`, `"${ARRAY[@]}"`.
- Use `local` for all variables inside functions.

### Naming Conventions
- **Functions**: Prefixed with module name in `lower_snake_case` (e.g., `disk_detect`, `net_get_active_interface`).
- **Config variables**: `UPPER_SNAKE_CASE` prefixed with `PVE_` (e.g., `PVE_HOSTNAME`).
- **Local variables**: `lower_snake_case`.
- **Files**: `lower-kebab-case` for scripts, `UPPER-KEBAB-CASE.md` for docs.

### Module Pattern
Each `lib/*.sh` file:
1. Starts with a one-line description comment.
2. Only defines functions (no code executed at source time).
3. Functions are prefixed with the module name.
4. Returns non-zero on failure with descriptive stderr output.

### Comments
- Only for non-obvious logic, constraints, or workarounds.
- Never narrate what the code does ("increment counter", "return result").
- Template files document available placeholders at the top.

## Commit Messages

Format: `type: short description`

Types:
- `feat` -- new feature
- `fix` -- bug fix
- `refactor` -- code restructuring
- `docs` -- documentation only
- `test` -- test additions/changes
- `chore` -- maintenance tasks

The commit body should explain *why*, not *what*.

## Testing

### Running Tests
```bash
bash tests/run-all.sh
```

### Writing Tests
- Add test files under `tests/` named `test-<module>.sh`.
- Each test function should be named `test_<description>`.
- Use `assert_equals`, `assert_true` from the test helper.
- Test edge cases and error conditions.

### Manual Testing
- Test in an actual Hetzner Rescue System when possible.
- For local development, verify individual module functions.
- Always test both interactive and unattended modes.

## Reporting Issues

Include:
1. Server model (e.g., AX-102, EX-44).
2. Output of `predict-check` and `lsblk`.
3. The full log file from `logs/pve-install-*.log`.
4. The generated `answer.toml` (with password redacted).

## Branding

This project is branded as a Corelix.io product. When contributing:
- Do not remove or alter the "Provided freely by Corelix.io - Made in France" attribution.
- Do not change the project name or branding in the UI, banner, or reports.
- Derivative works and forks must comply with the branding protection clause in the LICENSE.

## License

By contributing, you agree that your contributions will be licensed under the
BSD 3-Clause License with Branding Protection. See [LICENSE](../LICENSE) for details.
