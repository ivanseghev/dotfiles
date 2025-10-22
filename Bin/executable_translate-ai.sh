#!/usr/bin/env bash

# === CONFIG ===
# API Keys
OPENROUTER_API_KEY="$OPENROUTER_API_KEY"
GROQ_API_KEY="$GROQ_API_KEY"

# Endpoints
OPENROUTER_ENDPOINT="https://openrouter.ai/api/v1/chat/completions"
GROQ_ENDPOINT="https://api.groq.com/openai/v1/chat/completions"
SYSTEM_LOCAL_ENDPOINT="http://127.0.0.1:8000/v1/chat/completions"
DOCKER_LOCAL_ENDPOINT="http://localhost:8000/v1/chat/completions"

# Default Models
# ALL_MODELS="SYSTEM:llama-3.2-3B-Instruct-Q4_K_M!DOCKER:llama-3.2-3B-Instruct-Q4_K_M!OPENROUTER:mistral-7b-instruct!OPENROUTER:llama-3-8b-instruct!GROQ:llama-3.1-8b-instant!GROQ:llama-3.3-70b-versatile!GROQ:gemma2-9b-it"
ALL_MODELS="GROQ:llama-3.3-70b-versatile!GROQ:gemma2-9b-it!OPENROUTER:mistralai/mistral-7b-instruct:free!OPENROUTER:meta-llama/llama-3.3-70b-instruct:free!DOCKER:llama-3.2-3B-Instruct-Q4_K_M!SYSTEM:llama-3.2-3B-Instruct-Q4_K_M"

# === Speech to text ===
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

# === End of dictation ===

# Ensure UTF-8 locale for yad
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Sanitize text
TEXT=$(iconv -f UTF-8 -t UTF-8//IGNORE <<< "$TEXT")

# === YAD FORM ===
FORM=$(yad --width=800 --height=500 --center \
    --title="Grammar & Lexical Check" \
    --form \
    --field="Model:CB" "$ALL_MODELS" \
    --field="Enter text:TXT" "$TEXT")

# Cancel pressed
[ $? -ne 0 ] && exit 0


# Parse selection
MODEL_SELECTED=$(echo "$FORM" | cut -d'|' -f1)
INPUT_TEXT=$(echo "$FORM" | cut -d'|' -f2-)

# Extract provider and model name
PROVIDER=$(echo "$MODEL_SELECTED" | cut -d':' -f1)
MODEL_NAME=$(echo "$MODEL_SELECTED" | cut -d':' -f2-)

# === Map provider to endpoint & auth ===
case "$PROVIDER" in
    "SYSTEM")
        ENDPOINT="$SYSTEM_LOCAL_ENDPOINT"
        AUTH_HEADER=""
        ;;
    "DOCKER")
        ENDPOINT="$DOCKER_LOCAL_ENDPOINT"
        AUTH_HEADER=""
        ;;
    "OPENROUTER")
        ENDPOINT="$OPENROUTER_ENDPOINT"
        AUTH_HEADER="Authorization: Bearer $OPENROUTER_API_KEY"
        ;;
    "GROQ")
        ENDPOINT="$GROQ_ENDPOINT"
        AUTH_HEADER="Authorization: Bearer $GROQ_API_KEY"
        ;;
    *)
        yad --text="Unknown provider" --button=OK
        exit 1
        ;;
esac

# === PROMPT TO SEND TO LLM ===
PROMPT="You are a professional bilingual translator specializing in Russian-to-English translation. 
Your task is to produce accurate, fluent, and natural-sounding English translations of Russian text. 
You must:
- Correct minor spelling, grammatical, or stylistic issues if they exist in the source.
- Keep meaning, tone, and nuance faithful to the original.
- Do not explain, comment, or include transliterations.
- Output only the translated English text, nothing else.

Text:
$INPUT_TEXT"

ESCAPED_PROMPT=$(printf "%s" "$PROMPT" | jq -Rs '.')

# === REQUEST ===
RESPONSE=$(curl -s "$ENDPOINT" \
    -H "Content-Type: application/json" \
    ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
    -d "{
      \"model\": \"$MODEL_NAME\",
      \"messages\": [{\"role\": \"user\", \"content\": $ESCAPED_PROMPT}],
      \"temperature\": 0.3
    }" | jq -r '.choices[0].message.content')


# === SHOW RESULT ===
yad --width=600 --height=400 \
    --title="Translation" \
    --text-info \
    --wrap <<< "$RESPONSE"

# Extract only the corrected text
# CORRECTED=$(echo "$RESPONSE" | sed -n '/1\. Corrected text:/,/2\./p' | sed '1d;$d' | sed '/^$/d')

# Copy to clipboard (Linux X11/Wayland with xclip or wl-copy)
echo "$RESPONSE" | xclip -selection clipboard
