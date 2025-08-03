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

# === YAD FORM ===
FORM=$(yad --width=800 --height=500 --center \
    --title="Grammar & Lexical Check" \
    --form \
    --field="Model:CB" "$ALL_MODELS" \
    --field="Enter text:TXT" "")

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
PROMPT="You are an English language tutor. 
Analyze the following text for grammar and vocabulary issues.
Output:
1. Corrected text
2. Explanation of the changes
3. Example sentences for improved usage.

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


# === REQUEST ===
# RAW_RESPONSE=$(mktemp)
# curl -s "$ENDPOINT" \
#     -H "Content-Type: application/json" \
#     ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
#     -d "{
#       \"model\": \"$MODEL_NAME\",
#       \"messages\": [{\"role\": \"user\", \"content\": $ESCAPED_PROMPT}],
#       \"temperature\": 0.3
#     }" | tee "$RAW_RESPONSE" >/dev/null

# === DEBUG OUTPUT ===
# echo "---- RAW API RESPONSE ----"
# cat "$RAW_RESPONSE"
# echo "--------------------------"

# === PARSE RESPONSE ===
# RESPONSE=$(jq -r '.choices[0].message.content // empty' "$RAW_RESPONSE")

# === SHOW RESULT ===
yad --width=600 --height=400 \
    --title="Grammar & Vocabulary Analysis" \
    --text-info \
    --wrap <<< "$RESPONSE"

