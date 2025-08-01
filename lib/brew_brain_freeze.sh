#!/usr/bin/env bash
set -euo pipefail

INPUT=""
PREVIOUS=""
OUTPUT="freeze.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) INPUT="$2"; shift 2;;
    --previous) PREVIOUS="$2"; shift 2;;
    --output) OUTPUT="$2"; shift 2;;
    --help)
      echo "Usage: $0 --input latest.json --previous current.json --output freeze.json"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ -z "$INPUT" || -z "$PREVIOUS" ]]; then
  echo "❌ Must specify --input and --previous JSON files."
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "❌ 'jq' is required. Install with: brew install jq"
  exit 1
fi

# Perform the freeze comparison
jq -s '
  (.[0].tools | map(.name)) as $prevnames
  |
  [.[1].tools[] | select(.name as $n | $prevnames | index($n) | not)]
' "$PREVIOUS" "$INPUT" > "$OUTPUT"

# Count how many are new raymonepping tools
new_count=$(jq '[.[] | select(.source | test("raymonepping"))] | length' "$OUTPUT")

# Count total raymonepping tools in arsenal (INPUT)
total_count=$(jq '[.tools[] | select(.source | test("raymonepping"))] | length' "$INPUT")

echo "🧊 Freeze file written to: $OUTPUT"
echo "🔄 Compared: $INPUT vs $PREVIOUS"

if [[ "$new_count" -gt 0 ]]; then
  echo "📦 Found $new_count new tool(s) from Raymon Epping in Frozen state."
else
  echo "📭 No new tools from Raymon Epping found."
fi

echo "🧮 Total tools by Raymon Epping in arsenal: $total_count"
echo "✅ Finished comparison"
