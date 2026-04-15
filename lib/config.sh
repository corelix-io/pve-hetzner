# CLI argument parsing, config file loading, and defaults
# shellcheck shell=bash

# All config variables are prefixed with PVE_
# Precedence: defaults < config file < CLI args < interactive prompts

declare -g PVE_HOSTNAME=""
declare -g PVE_FQDN=""
declare -g PVE_TIMEZONE=""
declare -g PVE_EMAIL=""
declare -g PVE_ROOT_PASSWORD=""
declare -g PVE_SSH_KEYS=""
declare -g PVE_PRIVATE_SUBNET=""
declare -g PVE_INTERFACE=""
declare -g PVE_DISK_MODE=""        # auto, manual
declare -g PVE_DISKS=""            # comma-separated list
declare -g PVE_FILESYSTEM="zfs"
declare -g PVE_ZFS_RAID="raid1"
declare -g PVE_ZFS_COMPRESS="lz4"
declare -g PVE_ZFS_ASHIFT=""
declare -g PVE_ZFS_ARC_MAX=""
declare -g PVE_KEYBOARD="en-us"
declare -g PVE_COUNTRY="us"
declare -g PVE_ISO_PATH=""
declare -g PVE_BOOT_MODE=""        # auto, uefi, legacy
declare -g PVE_DNS_SERVERS="185.12.64.1 185.12.64.2"
declare -g PVE_UNATTENDED=false
declare -g PVE_CONFIG_FILE=""
declare -g PVE_SKIP_CONFIRM=false
declare -g PVE_LOG_LEVEL=1
declare -g PVE_WORKING_DIR="/root"
declare -g PVE_DEBIAN_SUITE="trixie"
declare -g PVE_NETWORK_MODE="nat"  # nat, routed, bridged

# Derived values (populated during detection/config)
declare -g PVE_MAIN_IPV4=""
declare -g PVE_MAIN_IPV4_CIDR=""
declare -g PVE_MAIN_IPV4_GW=""
declare -g PVE_MAC_ADDRESS=""
declare -g PVE_IPV6=""
declare -g PVE_IPV6_CIDR=""
declare -g PVE_PRIVATE_IP=""
declare -g PVE_PRIVATE_IP_CIDR=""
declare -g PVE_PREDICTED_IFACE=""
declare -g PVE_FIRST_IPV6_CIDR=""
declare -g PVE_QEMU_CPUS=""
declare -g PVE_QEMU_RAM_MB=""
declare -g PVE_INSTALL_START_TIME=""

config_load_defaults() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local defaults_file="${script_dir}/configs/default.env"

    if [[ -f "$defaults_file" ]]; then
        log_debug "Loading defaults from ${defaults_file}"
        config_load_file "$defaults_file"
    fi
}

config_load_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        die "Config file not found: ${file}"
    fi

    log_info "Loading configuration from ${file}"

    local key value
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        key="$(echo "$key" | xargs)"
        value="$(echo "$value" | xargs | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"

        case "$key" in
            PVE_HOSTNAME)       PVE_HOSTNAME="$value" ;;
            PVE_FQDN)           PVE_FQDN="$value" ;;
            PVE_TIMEZONE)       PVE_TIMEZONE="$value" ;;
            PVE_EMAIL)          PVE_EMAIL="$value" ;;
            PVE_ROOT_PASSWORD)  PVE_ROOT_PASSWORD="$value" ;;
            PVE_SSH_KEYS)       PVE_SSH_KEYS="$value" ;;
            PVE_PRIVATE_SUBNET) PVE_PRIVATE_SUBNET="$value" ;;
            PVE_INTERFACE)      PVE_INTERFACE="$value" ;;
            PVE_DISK_MODE)      PVE_DISK_MODE="$value" ;;
            PVE_DISKS)          PVE_DISKS="$value" ;;
            PVE_FILESYSTEM)     PVE_FILESYSTEM="$value" ;;
            PVE_ZFS_RAID)       PVE_ZFS_RAID="$value" ;;
            PVE_ZFS_COMPRESS)   PVE_ZFS_COMPRESS="$value" ;;
            PVE_ZFS_ASHIFT)     PVE_ZFS_ASHIFT="$value" ;;
            PVE_ZFS_ARC_MAX)    PVE_ZFS_ARC_MAX="$value" ;;
            PVE_KEYBOARD)       PVE_KEYBOARD="$value" ;;
            PVE_COUNTRY)        PVE_COUNTRY="$value" ;;
            PVE_ISO_PATH)       PVE_ISO_PATH="$value" ;;
            PVE_BOOT_MODE)      PVE_BOOT_MODE="$value" ;;
            PVE_DNS_SERVERS)    PVE_DNS_SERVERS="$value" ;;
            PVE_NETWORK_MODE)   PVE_NETWORK_MODE="$value" ;;
            PVE_DEBIAN_SUITE)   PVE_DEBIAN_SUITE="$value" ;;
            PVE_LOG_LEVEL)      PVE_LOG_LEVEL="$value"; LOG_LEVEL="$value" ;;
            *)                  log_debug "Unknown config key: ${key}" ;;
        esac
    done < "$file"
}

config_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --hostname)       PVE_HOSTNAME="$2"; shift 2 ;;
            --fqdn)           PVE_FQDN="$2"; shift 2 ;;
            --timezone)       PVE_TIMEZONE="$2"; shift 2 ;;
            --email)          PVE_EMAIL="$2"; shift 2 ;;
            --password)       PVE_ROOT_PASSWORD="$2"; shift 2 ;;
            --ssh-keys)       PVE_SSH_KEYS="$2"; shift 2 ;;
            --private-subnet) PVE_PRIVATE_SUBNET="$2"; shift 2 ;;
            --interface)      PVE_INTERFACE="$2"; shift 2 ;;
            --disk-mode)      PVE_DISK_MODE="$2"; shift 2 ;;
            --disks)          PVE_DISKS="$2"; shift 2 ;;
            --filesystem)     PVE_FILESYSTEM="$2"; shift 2 ;;
            --zfs-raid)       PVE_ZFS_RAID="$2"; shift 2 ;;
            --zfs-compress)   PVE_ZFS_COMPRESS="$2"; shift 2 ;;
            --zfs-ashift)     PVE_ZFS_ASHIFT="$2"; shift 2 ;;
            --zfs-arc-max)    PVE_ZFS_ARC_MAX="$2"; shift 2 ;;
            --keyboard)       PVE_KEYBOARD="$2"; shift 2 ;;
            --country)        PVE_COUNTRY="$2"; shift 2 ;;
            --iso)            PVE_ISO_PATH="$2"; shift 2 ;;
            --boot-mode)      PVE_BOOT_MODE="$2"; shift 2 ;;
            --dns)            PVE_DNS_SERVERS="$2"; shift 2 ;;
            --network-mode)   PVE_NETWORK_MODE="$2"; shift 2 ;;
            --debian-suite)   PVE_DEBIAN_SUITE="$2"; shift 2 ;;
            --config)         PVE_CONFIG_FILE="$2"; shift 2 ;;
            --unattended)     PVE_UNATTENDED=true; shift ;;
            --yes|-y)         PVE_SKIP_CONFIRM=true; shift ;;
            --debug)          PVE_LOG_LEVEL=0; LOG_LEVEL=0; shift ;;
            --quiet)          PVE_LOG_LEVEL=2; LOG_LEVEL=2; shift ;;
            --help|-h)        config_show_help; exit 0 ;;
            --version|-v)     echo "pve-install ${PVE_INSTALLER_VERSION}"; exit 0 ;;
            *)
                die "Unknown option: $1 (use --help for usage)"
                ;;
        esac
    done
}

config_show_help() {
    cat <<'HELP'
Usage: pve-install.sh [OPTIONS]

Proxmox VE Installer for Hetzner Dedicated Servers
Provided freely by Corelix.io - Made in France
Author: Amir Moradi

OPTIONS:
  --hostname NAME       Set hostname (default: interactive)
  --fqdn FQDN           Set fully qualified domain name
  --timezone TZ          Set timezone (e.g., UTC, Europe/Berlin)
  --email EMAIL          Set admin email address
  --password PASS        Set root password
  --ssh-keys "KEY..."    Set SSH public keys (space-separated)
  --private-subnet CIDR  Private subnet for NAT (e.g., 192.168.26.0/24)
  --interface NAME       Network interface to use
  --disk-mode MODE       Disk selection: auto, manual (default: auto)
  --disks LIST           Comma-separated disk list (e.g., nvme0n1,nvme1n1)
  --filesystem FS        Filesystem: zfs, ext4, xfs (default: zfs)
  --zfs-raid LEVEL       ZFS RAID: raid0, raid1, raid10, raidz-1/2/3
  --zfs-compress ALG     ZFS compression: lz4, zstd, on, off
  --zfs-ashift N         ZFS ashift value
  --zfs-arc-max MiB      ZFS ARC max memory in MiB
  --keyboard LAYOUT      Keyboard layout (default: en-us)
  --country CODE         Country code (default: us)
  --iso PATH             Path to Proxmox ISO (skip download)
  --boot-mode MODE       Boot mode: auto, uefi, legacy
  --dns SERVERS          DNS servers (space-separated)
  --network-mode MODE    Network: nat, routed, bridged (default: nat)
  --config FILE          Load configuration from .env file
  --unattended           Run without interactive prompts
  --yes, -y              Skip confirmation prompts
  --debug                Enable debug logging
  --quiet                Suppress info-level output
  --help, -h             Show this help message
  --version, -v          Show version

EXAMPLES:
  # Interactive mode (prompts for all values)
  ./pve-install.sh

  # Fully unattended with config file
  ./pve-install.sh --config configs/myserver.env --unattended

  # Unattended with CLI arguments
  ./pve-install.sh --hostname pve1 --fqdn pve1.example.com \
      --password "s3cret" --timezone UTC --email admin@example.com \
      --unattended --yes
HELP
}

# Interactive configuration prompts
config_interactive() {
    log_info "Starting interactive configuration..."
    echo ""

    if [[ -z "$PVE_INTERFACE" ]]; then
        local default_iface
        default_iface="$(net_get_active_interface 2>/dev/null || echo "eth0")"
        local iface_list
        iface_list="$(net_list_interfaces_display 2>/dev/null || echo "eth0")"
        read -r -e -p "$(echo -e "  ${CLR_CYAN}?${CLR_RESET} Network interface (${iface_list}): ")" -i "$default_iface" PVE_INTERFACE
    fi

    net_extract_info "$PVE_INTERFACE"

    echo ""
    ui_section "Detected Network"
    ui_kv "Interface" "$PVE_INTERFACE"
    ui_kv "IPv4" "$PVE_MAIN_IPV4_CIDR"
    ui_kv "Gateway" "$PVE_MAIN_IPV4_GW"
    ui_kv "MAC" "$PVE_MAC_ADDRESS"
    [[ -n "$PVE_IPV6_CIDR" ]] && ui_kv "IPv6" "$PVE_IPV6_CIDR"
    echo ""

    if [[ -z "$PVE_HOSTNAME" ]]; then
        read -r -e -p "$(echo -e "  ${CLR_CYAN}?${CLR_RESET} Hostname: ")" -i "proxmox" PVE_HOSTNAME
    fi

    if [[ -z "$PVE_FQDN" ]]; then
        read -r -e -p "$(echo -e "  ${CLR_CYAN}?${CLR_RESET} FQDN: ")" -i "${PVE_HOSTNAME}.example.com" PVE_FQDN
    fi

    if [[ -z "$PVE_TIMEZONE" ]]; then
        read -r -e -p "$(echo -e "  ${CLR_CYAN}?${CLR_RESET} Timezone: ")" -i "UTC" PVE_TIMEZONE
    fi

    if [[ -z "$PVE_EMAIL" ]]; then
        read -r -e -p "$(echo -e "  ${CLR_CYAN}?${CLR_RESET} Admin email: ")" -i "admin@example.com" PVE_EMAIL
    fi

    if [[ -z "$PVE_PRIVATE_SUBNET" ]]; then
        read -r -e -p "$(echo -e "  ${CLR_CYAN}?${CLR_RESET} Private subnet: ")" -i "192.168.26.0/24" PVE_PRIVATE_SUBNET
    fi

    while [[ -z "$PVE_ROOT_PASSWORD" ]]; do
        read -r -s -p "$(echo -e "  ${CLR_CYAN}?${CLR_RESET} Root password: ")" PVE_ROOT_PASSWORD
        echo ""
        if [[ -z "$PVE_ROOT_PASSWORD" ]]; then
            ui_warn "Password cannot be empty"
        fi
    done

    config_derive_values
}

# Calculate derived values from user inputs
config_derive_values() {
    if [[ -n "$PVE_PRIVATE_SUBNET" ]]; then
        local prefix
        prefix="$(echo "$PVE_PRIVATE_SUBNET" | cut -d'/' -f1 | rev | cut -d'.' -f2- | rev)"
        PVE_PRIVATE_IP="${prefix}.1"
        local mask
        mask="$(echo "$PVE_PRIVATE_SUBNET" | cut -d'/' -f2)"
        PVE_PRIVATE_IP_CIDR="${PVE_PRIVATE_IP}/${mask}"
    fi

    if [[ -n "$PVE_IPV6_CIDR" ]]; then
        local ipv6_prefix
        ipv6_prefix="$(echo "$PVE_IPV6_CIDR" | cut -d'/' -f1 | cut -d':' -f1-4)"
        PVE_FIRST_IPV6_CIDR="${ipv6_prefix}:1::1/80"
    else
        PVE_FIRST_IPV6_CIDR=""
    fi

    # Try to predict the real interface name for post-install config
    if command -v predict-check &>/dev/null; then
        PVE_PREDICTED_IFACE="$(predict-check 2>/dev/null | awk -F' -> ' '{print $2}' | head -n1)"
    fi
    if [[ -z "$PVE_PREDICTED_IFACE" ]]; then
        PVE_PREDICTED_IFACE="$PVE_INTERFACE"
    fi

    log_debug "Derived: PRIVATE_IP_CIDR=${PVE_PRIVATE_IP_CIDR}"
    log_debug "Derived: PREDICTED_IFACE=${PVE_PREDICTED_IFACE}"
    log_debug "Derived: FIRST_IPV6_CIDR=${PVE_FIRST_IPV6_CIDR}"
}
