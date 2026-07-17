#!/usr/bin/env bash

# Rofi command
ROFI="rofi -dmenu -i -p 'Launch'"

# Menu entries (label | action)
OPTIONS=$(cat <<'EOF'
🖨 PrusaSlicer
🌐 OctoPrint
📦 STL Browser
EOF
)

stl_fzf_picker() {
  STL_DIR="$HOME/Downloads/STL"
  PREVIEW="/tmp/stl_preview.png"

  alacritty -e bash -c '
    cd "'"$STL_DIR"'" || exit 1

    find . -type f -iname "*.stl" | sed "s|^\./||" | \
    fzf --layout=reverse \
        --prompt="Enter runs Prusa Slicer, Alt-Enter runs FSTL > " \
        --preview-window=right:60% \
        --preview="
          simple-thumbnailer-stl -i {} -o '"$PREVIEW"' -s 512 >/dev/null 2>&1 &&
          chafa '"$PREVIEW"'
        " \
        --bind "enter:execute(prusa-slicer {} >/dev/null 2>&1 &)" \
        --bind "alt-enter:execute(fstl {} >/dev/null 2>&1 &)"
  '
}


CHOICE=$(echo "$OPTIONS" | $ROFI)

case "$CHOICE" in
  "🖨 PrusaSlicer")
    prusa-slicer &
    ;;
  "🌐 OctoPrint")
    xdg-open http://octoprint.local:5050 &
    ;;
  "📦 STL Browser")
  stl_fzf_picker
    ;;
  *)
    exit 0
    ;;
esac

