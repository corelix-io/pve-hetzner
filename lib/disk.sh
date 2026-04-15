# Disk discovery, selection, RAID validation, and QEMU argument building
# shellcheck shell=bash

declare -ga DETECTED_DISKS=()
declare -ga SELECTED_DISKS=()

disk_detect() {
    log_info "Detecting available disks..."
    DETECTED_DISKS=()

    local name size type tran model
    while IFS= read -r line; do
        name="$(echo "$line" | awk '{print $1}')"
        size="$(echo "$line" | awk '{print $2}')"
        type="$(echo "$line" | awk '{print $3}')"
        tran="$(echo "$line" | awk '{print $4}')"

        [[ "$type" != "disk" ]] && continue
        [[ "$name" == "loop"* ]] && continue
        [[ "$name" == "sr"* ]] && continue
        [[ "$name" == "fd"* ]] && continue

        # Get model info
        model="$(lsblk -dno MODEL "/dev/${name}" 2>/dev/null | xargs || echo "Unknown")"

        DETECTED_DISKS+=("${name}|${size}|${tran:-unknown}|${model}")
    done < <(lsblk -dpno NAME,SIZE,TYPE,TRAN 2>/dev/null | sed 's|/dev/||')

    if [[ ${#DETECTED_DISKS[@]} -eq 0 ]]; then
        die "No disks detected. Check that drives are connected."
    fi

    ui_success "Found ${#DETECTED_DISKS[@]} disk(s):"
    local idx=1
    for entry in "${DETECTED_DISKS[@]}"; do
        local d_name d_size d_tran d_model
        IFS='|' read -r d_name d_size d_tran d_model <<< "$entry"
        ui_detail "[${idx}] /dev/${d_name} -- ${d_size} (${d_tran}) ${d_model}"
        (( idx++ ))
    done
}

disk_select() {
    SELECTED_DISKS=()

    if [[ -n "$PVE_DISKS" ]]; then
        # User specified disks via CLI/config
        IFS=',' read -ra user_disks <<< "$PVE_DISKS"
        for ud in "${user_disks[@]}"; do
            ud="$(echo "$ud" | xargs)"
            # Validate disk exists
            local found=false
            for entry in "${DETECTED_DISKS[@]}"; do
                local d_name
                d_name="$(echo "$entry" | cut -d'|' -f1)"
                if [[ "$d_name" == "$ud" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "$found" == false ]]; then
                die "Specified disk not found: ${ud}"
            fi
            SELECTED_DISKS+=("$ud")
        done
        ui_success "Using specified disks: ${SELECTED_DISKS[*]}"
        return 0
    fi

    if [[ "$PVE_DISK_MODE" == "auto" ]] || [[ "$PVE_UNATTENDED" == true ]]; then
        # Auto-select: use all detected disks
        for entry in "${DETECTED_DISKS[@]}"; do
            local d_name
            d_name="$(echo "$entry" | cut -d'|' -f1)"
            SELECTED_DISKS+=("$d_name")
        done
        ui_success "Auto-selected ${#SELECTED_DISKS[@]} disk(s): ${SELECTED_DISKS[*]}"
        return 0
    fi

    # Interactive disk selection
    echo ""
    ui_info "Select disks for installation (space-separated numbers, or 'all'):"
    local answer
    read -r -e -p "$(echo -e "  ${CLR_CYAN}?${CLR_RESET} Disks: ")" -i "all" answer

    if [[ "$answer" == "all" ]]; then
        for entry in "${DETECTED_DISKS[@]}"; do
            local d_name
            d_name="$(echo "$entry" | cut -d'|' -f1)"
            SELECTED_DISKS+=("$d_name")
        done
    else
        for num in $answer; do
            local idx=$(( num - 1 ))
            if (( idx >= 0 && idx < ${#DETECTED_DISKS[@]} )); then
                local d_name
                d_name="$(echo "${DETECTED_DISKS[$idx]}" | cut -d'|' -f1)"
                SELECTED_DISKS+=("$d_name")
            else
                die "Invalid disk number: ${num}"
            fi
        done
    fi

    if [[ ${#SELECTED_DISKS[@]} -eq 0 ]]; then
        die "No disks selected"
    fi

    ui_success "Selected ${#SELECTED_DISKS[@]} disk(s): ${SELECTED_DISKS[*]}"
}

disk_validate_raid() {
    if [[ "$PVE_FILESYSTEM" != "zfs" ]]; then
        return 0
    fi

    validate_disk_count_for_raid "$PVE_ZFS_RAID" "${#SELECTED_DISKS[@]}"
}

# Build QEMU -drive arguments for all selected disks
disk_build_qemu_args() {
    local -a args=()
    for disk in "${SELECTED_DISKS[@]}"; do
        args+=("-drive" "file=/dev/${disk},format=raw,media=disk,if=virtio")
    done
    echo "${args[@]}"
}

# Build the disk-list for answer.toml using virtio names
disk_build_answer_list() {
    local -a virt_names=()
    local idx=0
    local letters="abcdefghijklmnopqrstuvwxyz"
    for _ in "${SELECTED_DISKS[@]}"; do
        local letter="${letters:$idx:1}"
        virt_names+=("\"vd${letter}\"")
        (( idx++ ))
    done

    local IFS=','
    echo "[${virt_names[*]}]"
}

# Get a human-readable disk summary for reports
disk_summary() {
    local count="${#SELECTED_DISKS[@]}"
    local first_entry=""
    for entry in "${DETECTED_DISKS[@]}"; do
        local d_name
        d_name="$(echo "$entry" | cut -d'|' -f1)"
        if [[ "$d_name" == "${SELECTED_DISKS[0]}" ]]; then
            first_entry="$entry"
            break
        fi
    done

    local d_size d_tran d_model
    IFS='|' read -r _ d_size d_tran d_model <<< "$first_entry"

    if [[ "$PVE_FILESYSTEM" == "zfs" ]]; then
        echo "${count}x ${d_tran} ${d_size} (ZFS ${PVE_ZFS_RAID})"
    else
        echo "${count}x ${d_tran} ${d_size} (${PVE_FILESYSTEM})"
    fi
}
