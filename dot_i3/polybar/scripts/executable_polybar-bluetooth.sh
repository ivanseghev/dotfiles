#!/usr/bin/env bash

ROFI_THEME=""
ADAPTER=$(bluetoothctl list | head -n1 | awk '{print $2}')

# List all paired devices and their states
list_devices() {
    local devices
    devices=$(bluetoothctl devices | awk '{$1=""; print substr($0,2)}')

    if [ -z "$devices" ]; then
        notify-send "Bluetooth" "No devices found"
        exit 0
    fi

    # Get connection state for each
    local menu=""
    while IFS= read -r device; do
        mac=$(echo "$device" | awk '{print $1}')
        name=$(echo "$device" | cut -d' ' -f2-)
        connected=$(bluetoothctl info "$mac" | grep "Connected: yes" >/dev/null && echo " (Connected)" || echo " (Disconnected)")
        menu+="$name [$mac]$connected\n"
    done <<< "$devices"

    choice=$(echo -e "$menu" | rofi -dmenu -p "Bluetooth Devices" $ROFI_THEME)

    if [ -n "$choice" ]; then
        mac=$(echo "$choice" | grep -oP '\[([0-9A-F:]{17})\]' | tr -d '[]')
        if [[ "$choice" == *"(Connected)"* ]]; then
            bluetoothctl disconnect "$mac" && notify-send "Bluetooth" "Disconnected $mac"
        else
            bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected $mac"
        fi
    fi
}

# Adapter power/scan menu
adapter_menu() {
    local status scan_status menu

    status=$(bluetoothctl show "$ADAPTER" | grep "Powered:" | awk '{print $2}')
    scan_status=$(bluetoothctl show "$ADAPTER" | grep "Discovering:" | awk '{print $2}')

    menu=""
    if [[ "$status" == "yes" ]]; then
        menu+="Power Off\n"
        if [[ "$scan_status" == "yes" ]]; then
            menu+="Stop Scan\n"
        else
            menu+="Start Scan\n"
        fi
    else
        menu+="Power On\n"
    fi

    choice=$(echo -e "$menu" | rofi -dmenu -p "Bluetooth Menu" $ROFI_THEME)

    case "$choice" in
        "Power On") bluetoothctl power on ;;
        "Power Off") bluetoothctl power off ;;
        "Start Scan") bluetoothctl scan on ;;
        "Stop Scan") bluetoothctl scan off ;;
    esac
}


# Main
case "$1" in
    --list-devices)
        list_devices
        ;;
    --menu)
        adapter_menu
        ;;
    *)
        echo "󰂯"
        ;;
esac

