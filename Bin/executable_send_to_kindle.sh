#!/bin/bash

KINDLE_MOUNT="/run/media/${USER}/Kindle"
DOCUMENTS_DIR="$KINDLE_MOUNT/documents"
DOWNLOADS_DIR="$HOME/Downloads"

# Ensure ebook-convert exists
if ! command -v ebook-convert &> /dev/null; then
    echo "❌ Calibre's ebook-convert not found. Please install Calibre."
    exit 1
fi

# Check mount
if [ ! -d "$KINDLE_MOUNT" ] || [ ! -d "$DOCUMENTS_DIR" ]; then
    notify-send "🔍 Kindle not mounted at $KINDLE_MOUNT"
    exit 1
fi

# Select books via fzf
echo "📂 Scanning for books in $DOWNLOADS_DIR..."
selected_files=$(find "$DOWNLOADS_DIR" -type f \( \
    -iname "*.pdf" -o -iname "*.epub" -o -iname "*.mobi" -o -iname "*.fb2" \
    \) | fzf --multi --prompt="Select books to send to Kindle: " --preview 'ebook-meta {} 2>/dev/null || file {}')

# Exit if nothing selected
[ -z "$selected_files" ] && echo "❌ No books selected." && exit 1

# Convert and copy
while IFS= read -r input_file; do
    filename=$(basename "$input_file")
    base="${filename%.*}"
    mobi_file="/tmp/${base}.mobi"

    # Skip conversion if already .mobi
    if [[ "${filename,,}" == *.mobi ]]; then
        echo "📤 Copying MOBI: $input_file → $DOCUMENTS_DIR/"
        cp -v "$input_file" "$DOCUMENTS_DIR/"
        continue
    fi

    echo "📚 Converting: $input_file → $mobi_file"
    ebook-convert "$input_file" "$mobi_file" || {
        echo "❌ Conversion failed for $input_file"
        continue
    }

    echo "📤 Copying to Kindle: $mobi_file → $DOCUMENTS_DIR/"
    cp -v "$mobi_file" "$DOCUMENTS_DIR/"
done <<< "$selected_files"

echo "✅ Done."
