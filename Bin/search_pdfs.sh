#!/bin/bash
# === CONFIG ===
PDF_DIR="$HOME/Bin/knots"       # Folder with your PDFs
READER="zathura"                           # PDF viewer: zathura, mupdf, evince
CACHE_FILE="/tmp/pdf_search_cache.txt"     # Cached search results
QUERY_FILE="/tmp/pdf_search_query.txt"     # Last query

# === Helper: Open PDF at page ===
open_pdf() {
  local pdf="$1"
  local page="$2"

  echo "📖 Opening '$pdf' at page $page"

  if [[ "$READER" == "zathura" ]]; then
    zathura "$pdf" --page="$page"
  elif [[ "$READER" == "mupdf" ]]; then
    mupdf "$pdf" "$page"
  elif [[ "$READER" == "evince" ]]; then
    evince --page-label="$page" "$pdf"
  else
    echo "❌ Unknown PDF reader: $READER"
  fi
}

# === Step 1: Ask to reuse cache or search anew ===
if [[ -f "$CACHE_FILE" ]] && [[ -s "$CACHE_FILE" ]]; then
  echo "🗃️  Cached results found for: $(cat "$QUERY_FILE")"
  read -rp "🔁 Reuse previous results? [Y/n]: " REUSE
else
  REUSE="n"
fi

if [[ "$REUSE" =~ ^[Nn]$ ]]; then
  # Ask for new query
  QUERY=$(fzf --prompt="Enter new search term: " --print-query --height=10 --reverse | head -n1)
  [[ -z "$QUERY" ]] && echo "❌ No query entered." && exit 1

  echo "$QUERY" > "$QUERY_FILE"

  # Search
  echo "🔍 Searching..."
  pdfgrep -Hin --page-number "$QUERY" "$PDF_DIR"/*.pdf > "$CACHE_FILE"

  if [[ ! -s "$CACHE_FILE" ]]; then
    echo "❌ No matches found."
    rm -f "$CACHE_FILE"
    exit 0
  fi
fi

# === Step 2: Select from cached results ===
while true; do
  SELECTED=$(cat "$CACHE_FILE" | fzf --prompt="📚 Select a match: " --height=40% --reverse)
  [[ -z "$SELECTED" ]] && echo "❌ Nothing selected. Exiting." && exit 0

  PDF_PATH=$(echo "$SELECTED" | cut -d: -f1)
  PAGE_NUM=$(echo "$SELECTED" | cut -d: -f2)

  open_pdf "$PDF_PATH" "$PAGE_NUM"

  echo
  read -rp "🔄 Return to result list? [Y/n]: " AGAIN
  [[ "$AGAIN" =~ ^[Nn]$ ]] && break
done

