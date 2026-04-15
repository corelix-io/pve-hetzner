# ISO download with checksum verification, dependency installation
# shellcheck shell=bash

readonly ISO_BASE_URL="https://enterprise.proxmox.com/iso"
readonly PVE_GPG_URL="https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg"

# Hetzner rescue has broken IPv6 connectivity; force IPv4 for all network ops
_iso_curl() {
    curl -4 "$@"
}

_iso_wget() {
    wget -4 "$@"
}

iso_install_dependencies() {
    log_info "Installing required packages..."

    # Force apt to use IPv4 only (Hetzner rescue IPv6 is unreliable)
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

    # Add Proxmox repository for auto-install-assistant
    local pve_list="/etc/apt/sources.list.d/pve-installer.list"
    echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > "$pve_list"

    ui_spinner_start "Fetching Proxmox GPG key"
    _iso_curl -fsSL -o /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg "$PVE_GPG_URL" 2>/dev/null
    ui_spinner_stop true

    ui_spinner_start "Updating package lists"
    apt-get -qq update >/dev/null 2>&1
    ui_spinner_stop true

    local packages=(
        qemu-system-x86
        proxmox-auto-install-assistant
        xorriso
        ovmf
        wget
        socat
    )

    ui_spinner_start "Installing packages: ${packages[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get install -yq "${packages[@]}" >/dev/null 2>&1
    ui_spinner_stop true

    # Verify critical binaries
    local missing=()
    command -v qemu-system-x86_64 >/dev/null || missing+=("qemu-system-x86_64")
    command -v proxmox-auto-install-assistant >/dev/null || missing+=("proxmox-auto-install-assistant")
    command -v xorriso >/dev/null || missing+=("xorriso")
    command -v socat >/dev/null || missing+=("socat")

    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required binaries after install: ${missing[*]}"
    fi

    ui_success "All dependencies installed"
}

iso_get_latest_url() {
    local base_url="$ISO_BASE_URL"
    log_debug "Fetching ISO list from ${base_url}/"

    local page
    page="$(_iso_curl -fsSL "${base_url}/" 2>/dev/null)" || die "Failed to fetch ISO listing"

    local latest_iso
    latest_iso="$(echo "$page" | grep -oP 'proxmox-ve_[0-9]+\.[0-9]+-[0-9]+\.iso' | sort -V | tail -n1)"

    if [[ -z "$latest_iso" ]]; then
        die "Could not find Proxmox VE ISO at ${base_url}/"
    fi

    echo "${base_url}/${latest_iso}"
}

iso_extract_version() {
    local iso_name="$1"
    echo "$iso_name" | grep -oP 'proxmox-ve_\K[0-9]+\.[0-9]+-[0-9]+' || echo "unknown"
}

iso_download() {
    local working_dir="${PVE_WORKING_DIR:-/root}"
    local iso_file="${working_dir}/pve.iso"

    # User-provided ISO
    if [[ -n "$PVE_ISO_PATH" ]]; then
        if [[ ! -f "$PVE_ISO_PATH" ]]; then
            die "Specified ISO not found: ${PVE_ISO_PATH}"
        fi
        if [[ "$PVE_ISO_PATH" != "$iso_file" ]]; then
            cp "$PVE_ISO_PATH" "$iso_file"
        fi
        ui_success "Using provided ISO: ${PVE_ISO_PATH}"
        return 0
    fi

    # Check if already downloaded
    if [[ -f "$iso_file" ]]; then
        ui_success "Proxmox ISO already present, skipping download"
        return 0
    fi

    # Discover latest ISO
    ui_spinner_start "Discovering latest Proxmox VE ISO"
    local iso_url
    iso_url="$(iso_get_latest_url)"
    ui_spinner_stop true

    local iso_name
    iso_name="$(basename "$iso_url")"
    local version
    version="$(iso_extract_version "$iso_name")"
    ui_info "Latest version: Proxmox VE ${version}"
    ui_info "URL: ${iso_url}"

    # Download ISO with progress
    ui_info "Downloading ISO (~1.2 GB)..."
    _iso_wget --progress=bar:force:noscroll -O "$iso_file" "$iso_url" 2>&1 | \
        grep --line-buffered -oP '\d+%' | \
        while IFS= read -r pct; do
            printf "\r  Downloading... %s" "$pct"
        done
    echo ""

    if [[ ! -f "$iso_file" ]]; then
        die "ISO download failed"
    fi

    local iso_size
    iso_size="$(du -h "$iso_file" | awk '{print $1}')"
    ui_success "ISO downloaded: ${iso_name} (${iso_size})"

    # Verify checksum if available
    iso_verify_checksum "$iso_url" "$iso_file"
}

iso_verify_checksum() {
    local iso_url="$1"
    local iso_file="$2"
    local sha_url="${iso_url}.sha256sum"

    log_debug "Attempting checksum verification from ${sha_url}"

    local sha_content
    sha_content="$(_iso_curl -fsSL "$sha_url" 2>/dev/null)" || {
        log_warn "SHA256 checksum file not available, skipping verification"
        ui_warn "Checksum verification skipped (not available)"
        return 0
    }

    local expected_hash
    expected_hash="$(echo "$sha_content" | awk '{print $1}')"

    if [[ -z "$expected_hash" ]]; then
        log_warn "Could not parse checksum, skipping verification"
        return 0
    fi

    ui_spinner_start "Verifying ISO checksum"
    local actual_hash
    actual_hash="$(sha256sum "$iso_file" | awk '{print $1}')"

    if [[ "$actual_hash" == "$expected_hash" ]]; then
        ui_spinner_stop true
        ui_success "Checksum verified: SHA256 matches"
    else
        ui_spinner_stop false
        die "Checksum mismatch! Expected: ${expected_hash}, Got: ${actual_hash}"
    fi
}

iso_prepare_autoinstall() {
    local working_dir="${PVE_WORKING_DIR:-/root}"
    local iso_file="${working_dir}/pve.iso"
    local answer_file="${working_dir}/generated/answer.toml"
    local output_file="${working_dir}/pve-autoinstall.iso"
    local firstboot_file="${working_dir}/generated/first-boot.sh"

    if [[ ! -f "$iso_file" ]]; then
        die "ISO file not found: ${iso_file}"
    fi
    if [[ ! -f "$answer_file" ]]; then
        die "Answer file not found: ${answer_file}"
    fi

    ui_spinner_start "Preparing auto-install ISO"

    local -a cmd=(
        proxmox-auto-install-assistant prepare-iso "$iso_file"
        --fetch-from iso
        --answer-file "$answer_file"
        --output "$output_file"
    )

    # Add first-boot hook if the script exists and assistant supports it
    if [[ -f "$firstboot_file" ]]; then
        chmod +x "$firstboot_file"
        if proxmox-auto-install-assistant prepare-iso --help 2>&1 | grep -q 'on-first-boot'; then
            cmd+=(--on-first-boot "$firstboot_file")
            log_info "First-boot hook included in ISO"
        else
            log_warn "proxmox-auto-install-assistant does not support --on-first-boot"
            log_warn "Will use SSH-based post-install configuration as fallback"
        fi
    fi

    "${cmd[@]}" >>"${LOG_FILE:-/dev/null}" 2>&1 || {
        ui_spinner_stop false
        die "Failed to prepare auto-install ISO"
    }

    ui_spinner_stop true
    ui_success "Auto-install ISO created: ${output_file}"
}
