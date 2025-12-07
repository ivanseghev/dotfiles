#!/bin/bash

PRIMARY="DP-1"
PROJECTOR="HDMI-1"

# Rofi menu
options=(
    "Mirror both"
    "Primary only"
    "Projector only"
    "Restart i3"
)

choice=$(printf "%s\n" "${options[@]}" | rofi -dmenu -p "Display Options:")

case "$choice" in
    "Mirror both")
        # Set DP-1 as primary and mirror HDMI-1
        xrandr --output "$PRIMARY" --auto --primary \
               --output "$PROJECTOR" --auto --same-as "$PRIMARY"
        ;;

    "Primary only")
        xrandr --output "$PRIMARY" --auto --primary \
               --output "$PROJECTOR" --off
        ;;

    "Projector only")
        xrandr --output "$PRIMARY" --off \
               --output "$PROJECTOR" --auto
        ;;

    "Restart i3")
        i3-msg restart
        ;;

    *)
        echo "No valid choice selected."
        ;;
esac

