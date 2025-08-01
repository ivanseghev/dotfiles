#!/bin/bash

WHISPER_BIN="/usr/bin/whisper-cli"
MODEL="$HOME/Models/ggml-small.bin"
TMP_WAV="/tmp/dictate.wav"
TMP_TXT="/tmp/dictation.txt"
LANG="ru"
TIMEOUT_SEC=30  # auto-stop after 30 seconds

# Function to translate Russian text to English
translate_ru_en() {
  curl -s -X POST http://localhost:5000/translate \
    -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg q "$1" --arg source "ru" --arg target "en" --arg format "text" \
      '{q: $q, source: $source, target: $target, format: $format}')" |
    jq -r '.translatedText'
}
# Start recording
arecord -f cd -t wav -r 16000 -c 1 "$TMP_WAV" &
REC_PID=$!

# Show YAD Stop button with timeout
yad --title="Translation" \
    --button="Stop":0 \
    --timeout="$TIMEOUT_SEC" \
    --timeout-indicator=bottom \
    --text="Recording voice...\n\nPress Stop or wait ${TIMEOUT_SEC}s" \
    --center \
    --undecorated \
    --on-top \
    --skip-taskbar


# When window closes or times out, stop recording
kill "$REC_PID" 2>/dev/null
wait "$REC_PID" 2>/dev/null

# Notify and transcribe
notify-send "🔎 Translation" "Transcribing..."
"$WHISPER_BIN" -m "$MODEL" -f "$TMP_WAV" -l "$LANG" -nt -otxt -of "${TMP_TXT%.*}" > /dev/null
TEXT=$(< "$TMP_TXT")

if [[ -z "$TEXT" ]]; then
  notify-send "❗ Translation failed" "No speech recognized"
  exit 1
fi

translated_text=$(translate_ru_en "$TEXT")
# echo "Translation: $translated_text"

# remove newline characters
translated_text=$(echo "$translated_text" | tr -d '\n')

# echo "Translation: $translated_text"
# Speak the translated text using Piper
# echo "$translated_text" | piper --model $HOME/Models/piper/en_US-lessac-low.onnx --output-raw 2>/dev/null | aplay -r 16000 -f S16_LE -t raw - 2>/dev/null

# === Copy to clipboard ===
echo "$translated_text" | xclip -selection clipboard

# === Final notify ===
notify-send "✅ Translation complete" "$translated_text"
