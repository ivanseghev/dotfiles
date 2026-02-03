#!/usr/bin/env zsh

TERMINAL="alacritty"
TITLE="${(C)1}"
# TITLE="${1^}"
CMD="$1"

# Check if a window with this title already exists
if i3-msg -t get_tree | grep -q "\"title\":\"$TITLE\""; then
    # Focus existing vifm window
    i3-msg "[title=\"$TITLE\"] focus"
else
    # Start vifm in a new terminal with a fixed title
    exec "$TERMINAL" --title "$TITLE" -e "$CMD"
fi

