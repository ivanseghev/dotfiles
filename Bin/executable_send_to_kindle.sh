#!/bin/bash

KINDLE_MOUNT="/run/media/${USER}/Kindle"
DOCUMENTS_DIR="$KINDLE_MOUNT/documents"

# Ensure ebook-convert exists
if ! command -v ebook-convert &> /dev/null; then
    echo "❌ Calibre's ebook-convert not found. Please install Calibre."
    exit 1
fi

# Ensure udiskie is available
# if ! command -v udiskie-mount &> /dev/null; then
#     echo "❌ udiskie-mount not found. Please install udiskie."
#     exit 1
# fi

# Check mount
if [ ! -d "$KINDLE_MOUNT" ] || [ ! -d "$DOCUMENTS_DIR" ]; then
    echo "🔍 Kindle not mounted at $KINDLE_MOUNT"
    exit 1
    # udiskie-mount -A -n kindle || {
    #     echo "❌ Failed to mount Kindle. Is it connected?"
    #     exit 1
    # }

    # Wait for mount to appear
    # for i in {1..10}; do
    #     [ -d "$DOCUMENTS_DIR" ] && break
    #     sleep 1
    # done
    #
    # if [ ! -d "$DOCUMENTS_DIR" ]; then
    #     echo "❌ Still can't find Kindle mount point at $DOCUMENTS_DIR"
    #     exit 1
    # fi
fi

# Convert and copy books
for input_file in "$@"; do
    if [ ! -f "$input_file" ]; then
        echo "⚠️ Skipping: $input_file not found."
        continue
    fi

    filename=$(basename "$input_file")
    base="${filename%.*}"
    mobi_file="/tmp/${base}.mobi"

    echo "📚 Converting: $input_file → $mobi_file"
    ebook-convert "$input_file" "$mobi_file" || {
        echo "❌ Conversion failed for $input_file"
        continue
    }

    echo "📤 Copying to Kindle: $mobi_file → $DOCUMENTS_DIR/"
    cp -v "$mobi_file" "$DOCUMENTS_DIR/"
done

echo "✅ Done."

