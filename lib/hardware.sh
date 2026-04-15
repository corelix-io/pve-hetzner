# CPU, RAM, boot mode detection, and KVM availability
# shellcheck shell=bash

hw_check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root"
    fi
    ui_success "Running as root"
}

hw_check_rescue() {
    # Hetzner rescue indicators (check multiple -- they vary across versions)
    if [[ -f /etc/hetzner-rescue ]]; then
        ui_success "Hetzner Rescue System detected"
        return 0
    fi

    if command -v installimage &>/dev/null; then
        ui_success "Hetzner Rescue System detected (installimage found)"
        return 0
    fi

    if [[ -f /etc/motd ]] && grep -qi 'hetzner\|rescue' /etc/motd 2>/dev/null; then
        ui_success "Hetzner Rescue System detected (motd)"
        return 0
    fi

    if grep -qi 'hetzner' /etc/resolv.conf 2>/dev/null; then
        ui_success "Hetzner Rescue System detected (DNS)"
        return 0
    fi

    # Fallback: check if running from tmpfs/nfs root (common for rescue)
    local root_fs
    root_fs="$(df / 2>/dev/null | tail -1 | awk '{print $1}')"
    if [[ "$root_fs" == "tmpfs" ]] || [[ "$root_fs" == "rootfs" ]] || [[ "$root_fs" == *"nfs"* ]]; then
        ui_success "RAM/NFS-based root filesystem detected (likely rescue)"
        return 0
    fi

    # Check for common rescue hostname patterns
    local hn
    hn="$(hostname 2>/dev/null || true)"
    if [[ "$hn" == *"rescue"* ]] || [[ "$hn" == *"hetzner"* ]]; then
        ui_success "Hetzner Rescue System detected (hostname)"
        return 0
    fi

    log_warn "Not running in Hetzner Rescue System. Proceed with caution."
    ui_warn "Rescue system not detected -- results may vary"
    return 0
}

hw_check_kvm() {
    if [[ ! -e /dev/kvm ]]; then
        log_info "KVM device not found, attempting to load modules..."
        modprobe kvm 2>/dev/null || true
        modprobe kvm_intel 2>/dev/null || modprobe kvm_amd 2>/dev/null || true

        if [[ ! -e /dev/kvm ]]; then
            die "KVM is not available. Check that virtualization is enabled in BIOS."
        fi
    fi
    ui_success "KVM acceleration available"
}

hw_detect_boot_mode() {
    if [[ -n "$PVE_BOOT_MODE" ]] && [[ "$PVE_BOOT_MODE" != "auto" ]]; then
        log_info "Boot mode override: ${PVE_BOOT_MODE}"
        return 0
    fi

    if [[ -d /sys/firmware/efi ]]; then
        PVE_BOOT_MODE="uefi"
        ui_success "Boot mode: UEFI"
    else
        PVE_BOOT_MODE="legacy"
        ui_success "Boot mode: Legacy BIOS"
    fi
}

hw_get_uefi_firmware() {
    if [[ "$PVE_BOOT_MODE" != "uefi" ]]; then
        echo ""
        return 0
    fi

    local candidates=(
        "/usr/share/OVMF/OVMF_CODE.fd"
        "/usr/share/ovmf/OVMF.fd"
        "/usr/share/edk2/ovmf/OVMF_CODE.fd"
        "/usr/share/qemu/OVMF.fd"
    )

    for fw in "${candidates[@]}"; do
        if [[ -f "$fw" ]]; then
            echo "$fw"
            return 0
        fi
    done

    die "UEFI firmware not found. Install ovmf: apt install ovmf"
}

hw_detect_cpu() {
    local total_cores
    total_cores="$(nproc 2>/dev/null || echo 4)"

    # Allocate up to 8 cores, leave at least 1 for the host
    local alloc=$(( total_cores > 1 ? total_cores - 1 : 1 ))
    if (( alloc > 8 )); then
        alloc=8
    fi

    PVE_QEMU_CPUS="$alloc"

    local model
    model="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "Unknown")"
    ui_kv "CPU" "${model}"
    ui_kv "Cores (total)" "${total_cores}"
    ui_kv "Cores (QEMU)" "${PVE_QEMU_CPUS}"
}

hw_detect_ram() {
    local total_kb
    total_kb="$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')"
    local total_mb=$(( total_kb / 1024 ))
    local total_gb=$(( total_mb / 1024 ))

    # Allocate 75% of RAM to QEMU, min 4GB, max 16GB
    local alloc_mb=$(( total_mb * 75 / 100 ))
    if (( alloc_mb < 4096 )); then
        alloc_mb=4096
    fi
    if (( alloc_mb > 16384 )); then
        alloc_mb=16384
    fi

    PVE_QEMU_RAM_MB="$alloc_mb"

    ui_kv "RAM (total)" "${total_gb} GB"
    ui_kv "RAM (QEMU)" "$(( alloc_mb / 1024 )) GB"
}

hw_detect_all() {
    hw_detect_boot_mode
    hw_detect_cpu
    hw_detect_ram
}
