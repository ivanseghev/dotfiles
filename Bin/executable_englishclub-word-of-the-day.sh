#!/usr/bin/env bash
# EnglishClub Word of the Day notifier (Cloudflare-friendly, quote-safe)
# Dependencies: curl, grep, sed, notify-send, date

set -e

IDIOM_URL="https://www.englishclub.com/ref/idiom-of-the-day.php"
PHRASAL_URL="https://www.englishclub.com/ref/phrasal-verb-of-the-day.php"
SLANG_URL="https://www.englishclub.com/ref/slang-of-the-day.php"

TMP_DIR="/tmp"
IDIOM_FILE="$TMP_DIR/englishclub_idiom.txt"
PHRASAL_FILE="$TMP_DIR/englishclub_phrasal.txt"
SLANG_FILE="$TMP_DIR/englishclub_slang.txt"

BROWSER_HEADERS=(
  -A "Mozilla/5.0 (X11; Linux x86_64; rv:118.0) Gecko/20100101 Firefox/118.0"
  -e "https://www.englishclub.com/"
  -H "Accept-Language: en-US,en;q=0.9"
  -L
)

fetch_page() {
    local url="$1"
    local outfile="$2"

    if [[ ! -f "$outfile" || $(find "$outfile" -mmin +720 2>/dev/null) ]]; then
        echo "Fetching $url"
        curl -s "${BROWSER_HEADERS[@]}" "$url" -o "$outfile.raw"

        if grep -q "Just a moment" "$outfile.raw"; then
            echo "⚠️  Cloudflare challenge still active for $url"
            rm -f "$outfile.raw"
            return
        fi

        local title meaning example

        title=$(grep -Eo '<h2[^>]*>.*</h2>' "$outfile.raw" | sed -E 's/<[^>]+>//g' | head -1)
        meaning=$(grep -A1 -i '<h3>Meaning' "$outfile.raw" | tail -n1 | sed -E 's/<[^>]+>//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        example=$(grep -A1 -i '<h3>For example' "$outfile.raw" | tail -n1 | sed -E 's/<[^>]+>//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        [[ -z "$meaning" ]] && meaning=$(grep -Eo '<p><strong>Meaning:[^<]*</p>' "$outfile.raw" | sed -E 's/<[^>]+>//g' | cut -d':' -f2- | sed 's/^[[:space:]]*//')
        [[ -z "$example" ]] && example=$(grep -Eo '<p><strong>Example:[^<]*</p>' "$outfile.raw" | sed -E 's/<[^>]+>//g' | cut -d':' -f2- | sed 's/^[[:space:]]*//')

        if [[ -n "$title" || -n "$meaning" || -n "$example" ]]; then
            {
                echo "$title"
                [[ -n "$meaning" ]] && echo "Meaning: $meaning"
                [[ -n "$example" ]] && echo "Example: $example"
            } > "$outfile"
            echo "✓ Parsed and saved to $outfile"
        else
            echo "⚠️ Parsing failed for $url"
        fi

        rm -f "$outfile.raw"
    fi
}

fetch_page "$IDIOM_URL" "$IDIOM_FILE"
fetch_page "$PHRASAL_URL" "$PHRASAL_FILE"
fetch_page "$SLANG_URL" "$SLANG_FILE"

notify() {
    local title="$1"
    local message="$2"
    [[ -z "$message" ]] && return 0
    notify-send --urgency=normal --expire-time=0 "$title" "$message"
}

while true; do
    hour=$(date +%H | sed 's/^0//')  # strip leading zero

    if (( hour >= 9 && hour <= 17 )); then
        case $(( (hour - 9) % 3 )) in
            0)
                title="Idiom of the Day"
                message="$(cat "$IDIOM_FILE" 2>/dev/null)"
                ;;
            1)
                title="Phrasal Verb of the Day"
                message="$(cat "$PHRASAL_FILE" 2>/dev/null)"
                ;;
            2)
                title="Slang of the Day"
                message="$(cat "$SLANG_FILE" 2>/dev/null)"
                ;;
        esac
        notify "$title" "$message"
    fi

    next_hour=$(date -d 'next hour' +%s)
    now=$(date +%s)
    sleep $(( next_hour - now ))
done

