#!/usr/bin/env bash
# Proxmox VE Hetzner Installer - Bootstrap
# Downloads the latest release bundle and runs the installer.
#
# One-liner usage:
#   curl -4fsSL https://github.com/corelix-io/pve-hetzner/releases/latest/download/install.sh | bash
#   curl -4fsSL https://github.com/corelix-io/pve-hetzner/releases/latest/download/install.sh | bash -s -- --unattended --config myserver.env
#
# Provided freely by Corelix.io - Made in France
# Author: Amir Moradi
set -euo pipefail

REPO="corelix-io/pve-hetzner"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║  Proxmox VE Installer for Hetzner Dedicated Servers     ║"
echo "  ║  Provided freely by Corelix.io - Made in France         ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""

# Force IPv4 -- Hetzner rescue has unreliable IPv6
export CURL_OPTS="-4"

# Discover latest release tag
echo "  Discovering latest release..."
TAG="$(curl -4fsSL "$API_URL" 2>/dev/null | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')"

if [[ -z "$TAG" ]]; then
    echo "  ERROR: Could not determine latest release. Using main branch fallback."
    TAG="main"
    BUNDLE_URL="https://github.com/${REPO}/archive/refs/heads/main.tar.gz"
    BUNDLE_DIR="pve-hetzner-main"
else
    echo "  Latest version: ${TAG}"
    BUNDLE="pve-hetzner-${TAG}"
    BUNDLE_URL="https://github.com/${REPO}/releases/download/${TAG}/${BUNDLE}.tar.gz"
    BUNDLE_DIR="${BUNDLE}"
fi

cd /root

echo "  Downloading..."
curl -4fsSL -o pve-installer.tar.gz "$BUNDLE_URL" || {
    echo ""
    echo "  ERROR: Download failed."
    echo "  Try manually: wget -4 ${BUNDLE_URL}"
    exit 1
}

echo "  Extracting..."
tar xzf pve-installer.tar.gz
rm -f pve-installer.tar.gz

echo "  Starting installer..."
echo ""

cd "${BUNDLE_DIR}"

# Reconnect stdin to the terminal so interactive prompts work
# (when invoked via 'curl | bash', stdin is the pipe, not the terminal)
exec bash pve-install.sh "$@" </dev/tty
