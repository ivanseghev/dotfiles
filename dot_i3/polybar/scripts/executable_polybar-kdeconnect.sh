#!/usr/bin/env bash

# ================================
# CONFIG
# ================================
REFRESH_INTERVAL=5       # Seconds between updates in Polybar
ROFI_THEME=""             # Optional: --theme path/to/theme.rasi

# ================================
# FUNCTIONS
# ================================

# Get connected devices (only paired & reachable)
get_devices() {
    kdeconnect-cli -a --id-only 2>/dev/null
}

# Get default device (first connected)
get_default_device() {
    get_devices | head -n 1
}

# Polybar status output
show_status() {
    local devices
    devices=$(get_devices)

    if [ -z "$devices" ]; then
        echo "!"  # Icon for disconnected
    else
        echo ""  # Icon for connected
    fi
}

# Show devices list in rofi
show_device_list() {
    local devices device_names
    devices=$(get_devices)
    if [ -z "$devices" ]; then
        notify-send "KDE Connect" "No connected devices"
        exit 0
    fi

    device_names=""
    while read -r id; do
        name=$(kdeconnect-cli -l)
        device_names+="$name\n"
    done <<< "$devices"

    selected=$(echo -e "$device_names" | rofi -dmenu -p "KDE Connect Device" $ROFI_THEME)
    if [ -n "$selected" ]; then
        selected_id=$(kdeconnect-cli -a | grep -F "$selected" | awk '{print $1}')
        show_device_menu "$selected_id"
    fi
}

# Show actions for one device
show_device_menu() {
    local id="$1"
    local options="Pair\nPing\nFind Device\nSend File\nUnpair"

    selected=$(echo -e "$options" | rofi -dmenu -p "KDE Connect Actions" $ROFI_THEME)

    case "$selected" in
        "Pair") kdeconnect-cli -d "$id" --pair ;;
        "Ping") kdeconnect-cli -d "$id" --ping ;;
        "Find Device") kdeconnect-cli -d "$id" --ring ;;
        "Send File")
            file=$(zenity --file-selection)
            [ -n "$file" ] && kdeconnect-cli -d "$id" --share "$file"
            ;;
        "Unpair") kdeconnect-cli -d "$id" --unpair ;;
    esac
}

# ================================
# MAIN
# ================================

case "$1" in
    --menu)
        show_device_list
        ;;
    --device-menu)
        id=$(get_default_device)
        [ -n "$id" ] && show_device_menu "$id"
        ;;
    *)
        show_status
        ;;
esac

