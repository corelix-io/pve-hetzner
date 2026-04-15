#!/usr/bin/env bash
# Unit tests for lib/config.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/logging.sh"
LOG_LEVEL=4
LOG_QUIET=true
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/validate.sh"
source "${SCRIPT_DIR}/lib/network.sh"
source "${SCRIPT_DIR}/lib/config.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    (( TESTS_RUN++ )) || true
    if [[ "$expected" == "$actual" ]]; then
        (( TESTS_PASSED++ )) || true
        echo "  PASS: ${desc}"
    else
        (( TESTS_FAILED++ )) || true
        echo "  FAIL: ${desc} (expected '${expected}', got '${actual}')"
    fi
}

echo "=== config.sh tests ==="

# Test CLI argument parsing
config_parse_args --hostname "testhost" --fqdn "test.example.com" --timezone "UTC"
assert_eq "parse --hostname" "testhost" "$PVE_HOSTNAME"
assert_eq "parse --fqdn" "test.example.com" "$PVE_FQDN"
assert_eq "parse --timezone" "UTC" "$PVE_TIMEZONE"

# Test --unattended flag
config_parse_args --unattended
assert_eq "parse --unattended" "true" "$PVE_UNATTENDED"

# Test --yes flag
config_parse_args --yes
assert_eq "parse --yes" "true" "$PVE_SKIP_CONFIRM"

# Test --debug flag
config_parse_args --debug
assert_eq "parse --debug" "0" "$PVE_LOG_LEVEL"

# Test config file loading
TMPFILE="$(mktemp)"
cat > "$TMPFILE" <<'EOF'
PVE_HOSTNAME="fromfile"
PVE_EMAIL="test@test.com"
PVE_FILESYSTEM="ext4"
EOF
config_load_file "$TMPFILE"
assert_eq "load file hostname" "fromfile" "$PVE_HOSTNAME"
assert_eq "load file email" "test@test.com" "$PVE_EMAIL"
assert_eq "load file filesystem" "ext4" "$PVE_FILESYSTEM"
rm -f "$TMPFILE"

# Test derive_values
PVE_PRIVATE_SUBNET="192.168.50.0/24"
PVE_IPV6_CIDR=""
config_derive_values
assert_eq "derive private IP" "192.168.50.1" "$PVE_PRIVATE_IP"
assert_eq "derive private CIDR" "192.168.50.1/24" "$PVE_PRIVATE_IP_CIDR"
assert_eq "derive first IPv6 (empty)" "" "$PVE_FIRST_IPV6_CIDR"

echo ""
echo "Results: ${TESTS_PASSED}/${TESTS_RUN} passed, ${TESTS_FAILED} failed"

exit "$TESTS_FAILED"
