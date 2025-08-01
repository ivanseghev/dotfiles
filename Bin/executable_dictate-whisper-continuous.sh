#!/bin/bash

WHISPER_BIN="/usr/bin/whisper-cli"
MODEL="$HOME/Models/ggml-small.bin"
TMP_WAV="/tmp/dictate.wav"
TMP_TXT="/tmp/dictation.txt"
LANG="ru"
TIMEOUT_SEC=30  # auto-stop after 30 seconds

# Start recording
arecord -f cd -t wav -r 16000 -c 1 "$TMP_WAV" &
REC_PID=$!

# Show YAD Stop button with timeout
yad --title="Dictation" \
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
notify-send "🔎 Dictation" "Transcribing..."
"$WHISPER_BIN" -m "$MODEL" -f "$TMP_WAV" -l "$LANG" -nt -otxt -of "${TMP_TXT%.*}" > /dev/null
TEXT=$(< "$TMP_TXT")

if [[ -z "$TEXT" ]]; then
  notify-send "❗ Dictation failed" "No speech recognized"
  exit 1
fi

echo "$TEXT" | xclip -selection clipboard
notify-send "✅ Dictation complete" "$TEXT"

