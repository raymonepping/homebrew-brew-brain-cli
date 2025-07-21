#!/usr/bin/env bash
set -euo pipefail

log() { echo "🧠 [brew_brain] $*"; }

FILTER=""
INCLUDE_CASK=false
OUTPUT_FILE=".brew_brain.json"

# --- Parse CLI args ---
for arg in "$@"; do
  case "$arg" in
    --filter=*)
      FILTER="${arg#*=}"
      ;;
    --include-cask)
      INCLUDE_CASK=true
      ;;
    --output=*)
      OUTPUT_FILE="${arg#*=}"
      ;;
  esac
done

log "This might take a while... ☕️ Sharpen your mind and enjoy a coffee!"
SECONDS=0

echo '{ "tools": [' > "$OUTPUT_FILE"
first=true

get_install_cmd() {
  local full_name="$1"
  local tap="$2"
  local type="$3"   # formula or cask

  if [[ "$full_name" =~ ^([^/]+/[^/]+)/([^/]+)$ ]] && [[ "${BASH_REMATCH[1]##*/}" == "${BASH_REMATCH[2]//_/-}" ]]; then
    full_name="${BASH_REMATCH[1]}"
  fi
  if [[ "$type" == "cask" ]]; then
    echo "brew install --cask $full_name"
  else
    echo "brew install $full_name"
  fi
}

formulas=$(brew list --formula)
$INCLUDE_CASK && formulas+=" $(brew list --cask)"

for formula in $formulas; do
  # Cask or formula?
  is_cask=false
  [[ $INCLUDE_CASK == true && $(brew list --cask | grep -Fx "$formula") ]] && is_cask=true

  info=$(brew info --json=v2 "$formula" 2>/dev/null || echo "")
  [[ -z "$info" || "$info" == "null" ]] && continue

  # Pull from correct key (formula or cask)
  if [[ "$is_cask" == true ]]; then
    name=$(echo "$info" | jq -r '.casks[0].token // "unknown"')
    desc=$(echo "$info" | jq -r '.casks[0].desc // "No description available"')
    full_name="$name"
    homepage=$(echo "$info" | jq -r '.casks[0].homepage // ""')
    tap=$(echo "$info" | jq -r '.casks[0].tap // ""')
    version=$(echo "$info" | jq -r '.casks[0].version // ""')
    type="cask"
  else
    name=$(echo "$info" | jq -r '.formulae[0].name // "unknown"')
    desc=$(echo "$info" | jq -r '.formulae[0].desc // "No description available"')
    full_name=$(echo "$info" | jq -r '.formulae[0].full_name // empty')
    homepage=$(echo "$info" | jq -r '.formulae[0].homepage // ""')
    tap=$(echo "$info" | jq -r '.formulae[0].tap // ""')
    version=$(echo "$info" | jq -r '.formulae[0].versions.stable // ""')
    [[ -z "$full_name" ]] && full_name="$name"
    type="formula"
  fi

  # Build install command
  install_cmd=$(get_install_cmd "$full_name" "$tap" "$type")

  # Handle tapless personal CLI from GitHub
  if [[ -z "$tap" && "$homepage" == *"github.com/raymonepping/"* ]]; then
    tap="raymonepping/${name//_/-}"
    install_cmd="brew install $tap"
  fi

  # Filter
  is_personal=false
  if [[ -n "$FILTER" && "$tap" == "$FILTER"* ]]; then
    is_personal=true
  fi

  # Write comma if needed
  [[ "$first" == true ]] && first=false || echo "," >> "$OUTPUT_FILE"

  # Write JSON
  {
    echo "  {"
    echo "    \"name\": \"$name\","
    echo "    \"description\": \"$desc\","
    echo "    \"repo\": \"homebrew-$name\","
    echo "    \"install\": \"$install_cmd\","
    echo "    \"version\": \"$version\"",
    echo "    \"source\": \"$tap\""
    [[ "$is_personal" == true ]] && echo "    ,\"filter\": \"personal\""
    echo "  }"
  } >> "$OUTPUT_FILE"
done

echo '], "install_command": "brew install {formula}" }' >> "$OUTPUT_FILE"

# --- Pretty-print and sort, in-place ---
jq '.tools |= sort_by(.name)' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

DURATION=$SECONDS
log "Pretty, sorted arsenal dumped to $OUTPUT_FILE"
log "That took $((DURATION/60)) min $((DURATION%60)) sec. Enjoy your day — your Homebrew brain is now sharper! ✅"