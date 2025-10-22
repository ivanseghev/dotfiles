#!/usr/bin/env bash
# sys-rofi.sh — Rofi launcher for functions defined in this script
# Add your own functions at the "ADD YOUR FUNCTIONS HERE" section.
# Any function whose name starts with "_" is treated as internal and hidden.

set -Eeuo pipefail

#######################################
# Config
#######################################
ROFI_BIN="${ROFI_BIN:-rofi}"
ROFI_OPTS=(-dmenu -i -p "  Translation Tools" -no-custom)
# Optional: point to a rofi theme; leave empty to use default
ROFI_THEME="${ROFI_THEME:-}"

# Preferred terminal(s), first found will be used
PREFERRED_TERMS=(alacritty kitty wezterm gnome-terminal konsole xfce4-terminal mate-terminal tilix terminator xterm)

# Editor fallback chain
PREFERRED_EDITORS=("${EDITOR:-}" nvim vim micro nano)

# Category line prefix (non-executable)
CATEGORY_PREFIX="::"

#######################################
# Internal helpers (hidden from menu)
#######################################
_find_terminal() {
  for t in "${PREFERRED_TERMS[@]}"; do
    [[ -n "$t" ]] || continue
    if command -v "$t" >/dev/null 2>&1; then
      echo "$t"
      return 0
    fi
  done
  return 1
}

_open_in_term() {
  local cmd="$1"
  local term
  if term=$(_find_terminal); then
    case "$term" in
      alacritty) "$term" -e bash -lc "$cmd" & ;;
      # alacritty) "$term" -e bash -c "export DISPLAY='${DISPLAY:-:0}'; export DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS:-}'; exec $cmd" & ;;
      kitty|wezterm|tilix|terminator) "$term" bash -lc "$cmd" & ;;
      gnome-terminal|xfce4-terminal|mate-terminal|konsole) "$term" -- bash -lc "$cmd" & ;;
      xterm) xterm -e bash -lc "$cmd" & ;;
      *) "$term" -e bash -lc "$cmd" & ;;
    esac
  else
    # Fallback: run detached without terminal (may not show curses UI)
    nohup bash -lc "$cmd" >/dev/null 2>&1 &
  fi
}

_confirm_rofi() {
  local prompt="${1:-Are you sure?}"
  local choice
  choice=$(printf "%s\n%s\n" "No" "Yes" | $ROFI_BIN "${ROFI_OPTS[@]}" -p "$prompt")
  [[ "$choice" == "Yes" ]]
}

_pick_editor() {
  for e in "${PREFERRED_EDITORS[@]}"; do
    [[ -n "$e" ]] || continue
    if command -v "$e" >/dev/null 2>&1; then
      echo "$e"
      return 0
    fi
  done
  echo "nano"
}

_need() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    $ROFI_BIN "${ROFI_OPTS[@]}" -p "Missing: $bin" <<< "OK" >/dev/null || true
    return 1
  fi
  return 0
}

# declare arrays
declare -a FUNC_LIST
declare -A FUNC_DESC
declare -A DESC_TO_FUNC

# Function to register new items
_register_func() {
  local func="$1"
  local desc="$2"
  FUNC_LIST+=("$func")
  FUNC_DESC["$func"]="$desc"
  DESC_TO_FUNC["$desc"]="$func"
}

#######################################
# ADD YOUR FUNCTIONS HERE
#######################################

# libretranslate ru-en
libretranslate() {
  $HOME/Bin/translate-whisper-continuous.sh
}
_register_func "libretranslate" "Libretranslate Ru-En"

# Translate using AI online
translate_ai() {
  $HOME/Bin/translate-ai.sh
}
_register_func "translate_ai" "Translate Online AI"

# Grammar check
grammar_fix() {
  $HOME/Bin/grammar_fix.sh
}
_register_func "grammar_fix" "Grammar & Lexical Check"

# Word definition
word_definition() {
  _open_in_term "$HOME/Bin/dict-fzf.sh"
}
_register_func "word_definition" "Word Definition Fzf + Reverso.net"

# open englishclub game in browser
englishclub_game() {
  $HOME/Bin/englishclub-game.py
}
_register_func "englishclub_game" "English Club Games"

#######################################
# Menu builder
#######################################
_build_menu_lines() {
  # Collect function names defined in this script
  # `declare -F` prints: "declare -f funcname"
  local f
  local all_funcs=()
  while read -r _ _ f; do
    all_funcs+=("$f")
  done < <(declare -F)

  # Exclude internal helpers and any function starting with "_"
  local exclude_set=(
    _find_terminal _open_in_term _confirm_rofi _pick_editor _need _register_func
    _add_category _build_menu_lines _run_choice _main
  )
  # Build an associative array for quick exclusion
  declare -A EXC=()
  for e in "${exclude_set[@]}"; do EXC["$e"]=1; done

  # To preserve a nicer order, we’ll define a manual ordered list:
  local ordered=(
    "$CATEGORY_PREFIX Translation"
     libretranslate
     translate_ai
     grammar_fix
    "$CATEGORY_PREFIX Tools"
     word_definition
     englishclub_game
  )

  # Print lines: "label\t description"
  for name in "${ordered[@]}"; do
    local desc="${FUNC_DESC[$name]:-}"
    if [[ "$name" == "$CATEGORY_PREFIX "* ]]; then
      printf "%s\n" "$name"
    else
      # Only show real functions that exist and are not excluded/internal
      if [[ -n "${EXC[$name]:-}" ]]; then
        continue
      fi
      if [[ "$name" == _* ]]; then
        continue
      fi
      if declare -F "$name" >/dev/null 2>&1; then
        if [[ -n "$desc" && "$desc" != "—" ]]; then
          # printf "%s\t%s\n" "$name" "$desc"
          printf "%s\n" "$desc"
        else
          printf "%s\n" "$name"
        fi
      fi
    fi
  done
}

_run_choice() {
  local choice="$1"
  # Ignore categories or empty
  [[ -z "$choice" ]] && return
  if [[ "$choice" == "$CATEGORY_PREFIX "* ]]; then
    return
  fi
  # get function name
  local func="${DESC_TO_FUNC[$choice]}"
  # Safety: ensure it's a function we actually have
  if declare -F "$func" >/dev/null 2>&1; then
    "$func"
  fi
}

_main() {
  if ! command -v "$ROFI_BIN" >/dev/null 2>&1; then
    echo "Error: rofi not found. Install rofi and try again." >&2
    exit 1
  fi

  # Support --list to print available entries in the terminal
  if [[ "${1:-}" == "--list" ]]; then
    _build_menu_lines
    exit 0
  fi

  local lines choice
  lines=$(_build_menu_lines)

  # If a theme is provided, include it.
  if [[ -n "$ROFI_THEME" ]]; then
    choice=$(printf "%s\n" "$lines" | "$ROFI_BIN" "${ROFI_OPTS[@]}" -theme "$ROFI_THEME")
  else
    choice=$(printf "%s\n" "$lines" | "$ROFI_BIN" "${ROFI_OPTS[@]}")
  fi

  _run_choice "$choice"
}

_main "$@"

