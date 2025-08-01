#!/bin/bash
# Toggle between HDMI and DP
current=$(ddcutil getvcp 60 | awk '{print $NF}')

if [ "$current" == "(sl=0x0f)" ]; then
    echo "Switching to HDMI..."
    ddcutil setvcp 60 0x11
else
    echo "Switching to DisplayPort..."
    ddcutil setvcp 60 0x0f
fi

