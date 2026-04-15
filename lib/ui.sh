# Terminal UI: colors, spinners, progress bars, branded banners
# shellcheck shell=bash

# Color codes
readonly CLR_RED="\033[1;31m"
readonly CLR_GREEN="\033[1;32m"
readonly CLR_YELLOW="\033[1;33m"
readonly CLR_BLUE="\033[1;34m"
readonly CLR_MAGENTA="\033[1;35m"
readonly CLR_CYAN="\033[1;36m"
readonly CLR_WHITE="\033[1;37m"
readonly CLR_GRAY="\033[0;37m"
readonly CLR_DIM="\033[2m"
readonly CLR_BOLD="\033[1m"
readonly CLR_RESET="\033[0m"

# Box-drawing characters
readonly BOX_H="─"
readonly BOX_V="│"
readonly BOX_TL="┌"
readonly BOX_TR="┐"
readonly BOX_BL="└"
readonly BOX_BR="┘"
readonly BOX_T="├"
readonly BOX_B="┤"
readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly ARROW="▶"
readonly BULLET="•"

# Spinner characters
readonly SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Project version
readonly PVE_INSTALLER_VERSION="2.0.0"

# Detect terminal capabilities
_ui_supports_color() {
    [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]
}

# Strip color codes for log files
_ui_strip_color() {
    sed 's/\x1b\[[0-9;]*m//g'
}

ui_banner() {
    local width=62
    local line
    line="$(printf '%*s' "$width" '' | tr ' ' "$BOX_H")"

    echo ""
    echo -e "${CLR_CYAN}${BOX_TL}${line}${BOX_TR}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}${CLR_BOLD}                                                              ${CLR_RESET}${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}${CLR_BOLD}   ██████╗ ██╗   ██╗███████╗    ██╗  ██╗███████╗████████╗    ${CLR_RESET}${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}${CLR_BOLD}   ██╔══██╗██║   ██║██╔════╝    ██║  ██║██╔════╝╚══██╔══╝    ${CLR_RESET}${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}${CLR_BOLD}   ██████╔╝██║   ██║█████╗      ███████║█████╗     ██║       ${CLR_RESET}${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}${CLR_BOLD}   ██╔═══╝ ╚██╗ ██╔╝██╔══╝      ██╔══██║██╔══╝     ██║       ${CLR_RESET}${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}${CLR_BOLD}   ██║      ╚████╔╝ ███████╗    ██║  ██║███████╗   ██║       ${CLR_RESET}${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}${CLR_BOLD}   ╚═╝       ╚═══╝  ╚══════╝    ╚═╝  ╚═╝╚══════╝   ╚═╝       ${CLR_RESET}${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}                                                              ${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}  ${CLR_WHITE}Proxmox VE Installer for Hetzner Dedicated Servers${CLR_RESET}          ${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}  ${CLR_DIM}Version ${PVE_INSTALLER_VERSION}${CLR_RESET}                                              ${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}                                                              ${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}  ${CLR_DIM}Provided freely by ${CLR_RESET}${CLR_WHITE}Corelix.io${CLR_RESET}${CLR_DIM} - Made in France${CLR_RESET}              ${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}  ${CLR_DIM}Author: Amir Moradi${CLR_RESET}                                        ${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_V}${CLR_RESET}                                                              ${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "${CLR_CYAN}${BOX_BL}${line}${BOX_BR}${CLR_RESET}"
    echo ""
}

# Phase header: [N/TOTAL] Description
ui_phase() {
    local current="$1"
    local total="$2"
    local description="$3"
    echo ""
    echo -e "${CLR_CYAN}${BOX_H}${BOX_H}${BOX_H} [${current}/${total}] ${description} ${BOX_H}${BOX_H}${BOX_H}${CLR_RESET}"
    echo ""
}

# Status messages
ui_success() {
    echo -e "  ${CLR_GREEN}${CHECK_MARK}${CLR_RESET} $*"
}

ui_fail() {
    echo -e "  ${CLR_RED}${CROSS_MARK}${CLR_RESET} $*"
}

ui_info() {
    echo -e "  ${CLR_BLUE}${ARROW}${CLR_RESET} $*"
}

ui_warn() {
    echo -e "  ${CLR_YELLOW}!${CLR_RESET} $*"
}

ui_detail() {
    echo -e "    ${CLR_DIM}${BULLET} $*${CLR_RESET}"
}

# Key-value display for reports
ui_kv() {
    local key="$1"
    local value="$2"
    local width="${3:-20}"
    printf "  ${CLR_DIM}%-${width}s${CLR_RESET} %s\n" "${key}:" "$value"
}

# Horizontal rule
ui_hr() {
    local width="${1:-60}"
    local char="${2:-$BOX_H}"
    printf "  ${CLR_DIM}"
    printf '%*s' "$width" '' | tr ' ' "$char"
    printf "${CLR_RESET}\n"
}

# Section header inside reports
ui_section() {
    echo ""
    echo -e "  ${CLR_BOLD}${CLR_WHITE}$*${CLR_RESET}"
    ui_hr 58
}

# Confirmation prompt (returns 0 for yes, 1 for no)
ui_confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-y}"

    if [[ "${PVE_UNATTENDED:-false}" == true ]]; then
        return 0
    fi

    local yn_hint
    if [[ "$default" == "y" ]]; then
        yn_hint="[Y/n]"
    else
        yn_hint="[y/N]"
    fi

    local answer
    read -r -p "$(echo -e "  ${CLR_YELLOW}?${CLR_RESET} ${prompt} ${yn_hint} ")" answer
    answer="${answer:-$default}"

    [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

# Spinner for background operations
# Usage: ui_spinner_start "message" ; do_work ; ui_spinner_stop
declare -g _SPINNER_PID=""
declare -g _SPINNER_MSG=""

ui_spinner_start() {
    _SPINNER_MSG="$1"
    (
        local i=0
        local len=${#SPINNER_CHARS}
        while true; do
            local char="${SPINNER_CHARS:$i:1}"
            printf "\r  ${CLR_CYAN}%s${CLR_RESET} %s" "$char" "$_SPINNER_MSG"
            i=$(( (i + 1) % len ))
            sleep 0.1
        done
    ) &
    _SPINNER_PID=$!
    disown "$_SPINNER_PID" 2>/dev/null
}

ui_spinner_stop() {
    local success="${1:-true}"
    if [[ -n "$_SPINNER_PID" ]]; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null || true
        _SPINNER_PID=""
    fi
    printf "\r\033[K"
    if [[ "$success" == true ]]; then
        ui_success "$_SPINNER_MSG"
    else
        ui_fail "$_SPINNER_MSG"
    fi
}

# Progress bar
# Usage: ui_progress 45 100 "Installing packages..."
ui_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-}"
    local width=40

    local percent=0
    if [[ "$total" -gt 0 ]]; then
        percent=$(( current * 100 / total ))
    fi
    local filled=$(( width * current / total ))
    local empty=$(( width - filled ))

    local bar
    bar="$(printf '%*s' "$filled" '' | tr ' ' '█')$(printf '%*s' "$empty" '' | tr ' ' '░')"

    printf "\r  ${CLR_CYAN}%s${CLR_RESET} %3d%% %s" "$bar" "$percent" "$message"

    if [[ "$current" -ge "$total" ]]; then
        echo ""
    fi
}

# Countdown timer
ui_countdown() {
    local seconds="$1"
    local message="${2:-Waiting}"

    for (( i=seconds; i>0; i-- )); do
        printf "\r  ${CLR_DIM}%s... %ds remaining${CLR_RESET}  " "$message" "$i"
        sleep 1
    done
    printf "\r\033[K"
}

# Display a boxed report section
ui_box_start() {
    local title="$1"
    local width=60
    local line
    line="$(printf '%*s' "$width" '' | tr ' ' "$BOX_H")"
    local title_line
    title_line="$(printf '%*s' $(( (width - ${#title}) / 2 )) '')${title}"

    echo ""
    echo -e "  ${CLR_CYAN}${BOX_TL}${line}${BOX_TR}${CLR_RESET}"
    echo -e "  ${CLR_CYAN}${BOX_V}${CLR_RESET}${CLR_BOLD}$(printf '%-60s' "$title_line")${CLR_RESET}${CLR_CYAN}${BOX_V}${CLR_RESET}"
    echo -e "  ${CLR_CYAN}${BOX_T}${line}${BOX_B}${CLR_RESET}"
}

ui_box_row() {
    local content="$1"
    local plain
    plain="$(echo -e "$content" | _ui_strip_color)"
    local pad=$(( 60 - ${#plain} ))
    [[ "$pad" -lt 0 ]] && pad=0
    echo -e "  ${CLR_CYAN}${BOX_V}${CLR_RESET} ${content}$(printf '%*s' "$pad" '')${CLR_CYAN}${BOX_V}${CLR_RESET}"
}

ui_box_end() {
    local width=60
    local line
    line="$(printf '%*s' "$width" '' | tr ' ' "$BOX_H")"
    echo -e "  ${CLR_CYAN}${BOX_BL}${line}${BOX_BR}${CLR_RESET}"
    echo ""
}

# Display a table of key-value pairs inside a box
ui_box_kv() {
    local key="$1"
    local value="$2"
    local kwidth="${3:-18}"
    local formatted
    formatted="$(printf "${CLR_DIM}%-${kwidth}s${CLR_RESET} %s" "$key" "$value")"
    ui_box_row "$formatted"
}
