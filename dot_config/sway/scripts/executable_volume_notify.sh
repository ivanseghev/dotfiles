#!/bin/bash
# Adjust volume or mute, then notify with current percentage

# Run the requested pactl command
"$@"

# Get default sink
SINK="@DEFAULT_SINK@"

# Ensure max 100%
pactl set-sink-volume "$SINK" 100%+0

# Query volume
VOL=$(pactl get-sink-volume "$SINK" | awk '{print $5}' | head -n1)

# Query mute status
MUTE=$(pactl get-sink-mute "$SINK" | awk '{print $2}')

if [ "$MUTE" = "yes" ]; then
    MSG="🔇 Muted"
else
    MSG="🔊 Volume: $VOL"
fi

# Send notification (replace -r ID to overwrite instead of stacking)
dunstify -a "Volume" -r 9112 "$MSG"

