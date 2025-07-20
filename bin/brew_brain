#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"

RAYMON_TAP="raymonepping"
EXPECTED=(
  bump-version-cli
  commit-gh-cli
  folder-tree-cli
  radar-love-cli
  repository-audit-cli
  repository-backup-cli
  self-doc-gen-cli
)

ACTION="human"
OUTPUT=""
OUTPUT_FILE=""

if ! command -v jq &>/dev/null; then
  echo "❌ This script requires 'jq'. Install it with: brew install jq"
  exit 1
fi

get_installed_brews() {
  local info
  readarray -t all < <(brew list --formula 2>/dev/null || true)
  [[ ${#all[@]} -eq 0 ]] && return
  info=$(brew info --json=v2 "${all[@]}" 2>/dev/null)
  mapfile -t BREWS < <(echo "$info" | jq -r '.formulae[]? | select((.tap // "") | test("'"$RAYMON_TAP"'")) | .name // empty')
}

get_installed_version() {
  brew info --json=v2 "$1" 2>/dev/null | jq -r '.formulae[0].versions.stable // empty'
}

get_latest_version() {
  local brew="$1" repo=""
  case "$brew" in
  bump-version-cli) repo="homebrew-bump-version-cli" ;;
  commit-gh-cli) repo="homebrew-commit-gh-cli" ;;
  folder-tree-cli) repo="homebrew-folder-tree-cli" ;;
  radar-love-cli) repo="homebrew-radar-love-cli" ;;
  repository-audit-cli) repo="homebrew-repository-audit-cli" ;;
  repository-backup-cli) repo="homebrew-repository-backup-cli" ;;
  self-doc-gen-cli) repo="homebrew-self-doc-gen-cli" ;;
  *)
    echo "–"
    return 1
    ;;
  esac

  local cache_file="/tmp/raymon_latest_${brew}.ver.json"
  if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file"))) -lt 300 ]]; then
    jq -r '.version // "–"' "$cache_file" 2>/dev/null && return
  fi

  local rel ver
  rel=$(curl -fsSL "https://api.github.com/repos/raymonepping/${repo}/releases/latest" 2>/dev/null || echo "")
  ver=$(echo "$rel" | jq -er '.tag_name // empty' 2>/dev/null | sed 's/^v//' || true)
  if [[ -n "$ver" && "$ver" != "null" ]]; then
    jq -n --arg version "$ver" '{version:$version,"source":"release"}' >"$cache_file"
    echo "$ver"
    return
  fi

  local tag_resp tag
  tag_resp=$(curl -fsSL "https://api.github.com/repos/raymonepping/${repo}/tags" 2>/dev/null || echo "")
  tag=$(echo "$tag_resp" | jq -er '[.[] | select(.name? and (.name | type == "string") and (.name | test("^v?[0-9]+\\.[0-9]+\\.[0-9]+$")) )][0].name // empty' 2>/dev/null | sed 's/^v//' || true)
  if [[ -n "$tag" && "$tag" != "null" ]]; then
    jq -n --arg version "$tag" '{version:$version,"source":"tag"}' >"$cache_file"
    echo "$tag"
    return
  fi

  jq -n --arg version "–" '{version:$version,"source":"none"}' >"$cache_file"
  echo "–"
}

render_human() {
  if [[ ${#BREWS[@]} -eq 0 ]]; then
    echo "❌ No Raymon CLI tools found via Homebrew."
    echo "💡 Try: brew tap raymonepping/folder-tree-cli (and others)"
    exit 1
  fi

  echo "🧠 Raymon's Homebrew CLI Arsenal (${#BREWS[@]} tools)"
  echo "────────────────────────────────────────────────────────────"

  for brew in "${BREWS[@]}"; do
    local_version=$(get_installed_version "$brew")
    latest_version=$(get_latest_version "$brew")
    symbol="✅"
    [[ "$local_version" != "$latest_version" && "$latest_version" != "–" ]] && symbol="⬆️"
    case "$brew" in
    bump-version-cli) desc="Semantic versioning + changelogs" ;;
    commit-gh-cli) desc="GitHub commit automation" ;;
    folder-tree-cli) desc="Visual folder structure + docs" ;;
    radar-love-cli) desc="Simulated secret leaks + scans" ;;
    repository-audit-cli) desc="Repo hygiene & reporting" ;;
    repository-backup-cli) desc="Modular backup + restore" ;;
    self-doc-gen-cli) desc="Generate README.md from scripts" ;;
    *) desc="(unknown purpose)" ;;
    esac

    if [[ "$local_version" == "$latest_version" ]]; then
      printf "%-2s %-28s %-10s   %-12s  %s\n" "$symbol" "$brew" "v$local_version" "" "$desc"
    else
      printf "%-2s %-28s %-10s → %-10s  %s\n" "$symbol" "$brew" "v$local_version" "v$latest_version" "$desc"
    fi
  done

  echo "────────────────────────────────────────────────────────────"
  echo "✨ Installed via: brew tap $RAYMON_TAP/*"
  echo "📦 Run: bump_version myscript.sh --patch --message \"Fix bug\""
}

render_markdown() {
  echo "| CLI | Description |"
  echo "|-----|-------------|"
  for brew in "${BREWS[@]}"; do
    case "$brew" in
    bump-version-cli) echo "| \`$brew\` | Semantic versioning + changelogs |" ;;
    commit-gh-cli) echo "| \`$brew\` | GitHub commit automation |" ;;
    folder-tree-cli) echo "| \`$brew\` | Visual folder structure + docs |" ;;
    radar-love-cli) echo "| \`$brew\` | Simulated secret leaks + scans |" ;;
    repository-audit-cli) echo "| \`$brew\` | Repo hygiene & reporting |" ;;
    repository-backup-cli) echo "| \`$brew\` | Modular backup + restore |" ;;
    self-doc-gen-cli) echo "| \`$brew\` | Generate README.md from scripts |" ;;
    *) echo "| \`$brew\` | Unknown |" ;;
    esac
  done
}

render_json() {
  echo "["
  local first=1
  for brew in "${BREWS[@]}"; do
    [[ $first -eq 0 ]] && echo ","
    first=0
    case "$brew" in
    bump-version-cli) desc="Semantic versioning + changelogs" ;;
    commit-gh-cli) desc="GitHub commit automation" ;;
    folder-tree-cli) desc="Visual folder structure + docs" ;;
    radar-love-cli) desc="Simulated secret leaks + scans" ;;
    repository-audit-cli) desc="Repo hygiene & reporting" ;;
    repository-backup-cli) desc="Modular backup + restore" ;;
    self-doc-gen-cli) desc="Generate README.md from scripts" ;;
    *) desc="Unknown" ;;
    esac
    echo "  { \"name\": \"$brew\", \"description\": \"$desc\" }"
  done
  echo "]"
}

render_table() {
  printf "%-25s %-10s %-10s\n" "CLI" "Local" "Latest"
  printf "%-25s %-10s %-10s\n" "---" "-----" "------"
  for brew in "${BREWS[@]}"; do
    local_version=$(get_installed_version "$brew")
    latest_version=$(get_latest_version "$brew")
    printf "%-25s %-10s %-10s\n" "$brew" "v$local_version" "v$latest_version"
  done
}

run_doctor() {
  echo "🩺 Running Raymon Doctor..."
  echo "──────────────────────────────────────────────"
  for name in "${EXPECTED[@]}"; do
    if [[ " ${BREWS[*]} " == *" $name "* ]]; then
      version=$(get_installed_version "$name")
      echo "✅ $name is installed (v$version)"
    else
      echo "❌ $name is missing"
    fi
  done
}

run_refresh() {
  echo "🔄 Checking for CLI updates from GitHub..."
  echo "──────────────────────────────────────────────"
  for brew in "${BREWS[@]}"; do
    local_version=$(get_installed_version "$brew")
    latest_version=$(get_latest_version "$brew")
    [[ "$latest_version" == "null" || -z "$latest_version" ]] && latest_version="–"
    if [[ "$latest_version" == "null" || -z "$latest_version" ]]; then
      echo "❓ $brew: unable to fetch latest release"
    elif [[ "$local_version" == "$latest_version" ]]; then
      echo "✅ $brew is up to date (v$local_version)"
    else
      echo "⬆️  $brew: local v$local_version → latest v$latest_version"
    fi
  done
}

run_checkup() {
  local config_file="$HOME/.brew_brain.json"
  if [[ ! -f "$config_file" ]]; then
    echo "❌ No config found at $config_file"
    echo "💡 Create one with:"
    echo '{
  "expected": [
    "bump-version-cli",
    "commit-gh-cli",
    "folder-tree-cli",
    "radar-love-cli",
    "repository-audit-cli",
    "repository-backup-cli",
    "self-doc-gen-cli"
  ]
}' >"$config_file"
    exit 1
  fi

  echo "🩺 Running brew_brain checkup..."
  echo "──────────────────────────────────────────────"

  mapfile -t EXPECTED_JSON < <(jq -r '.expected[]' "$config_file")
  for name in "${EXPECTED_JSON[@]}"; do
    if [[ " ${BREWS[*]} " == *" $name "* ]]; then
      version=$(get_installed_version "$name")
      echo "✅ $name is installed (v$version)"
    else
      echo "❌ $name is missing"
      read -rp "👉 Do you want to install $name now? (y/n): " answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "📦 Installing $name..."
        brew install "raymonepping/$name/$name"
      else
        echo "🚫 Skipping $name"
      fi
    fi
  done
}

# --- Argument parsing (handle order-agnostic) ---
while [[ $# -gt 0 ]]; do
  case "$1" in
  --refresh)
    ACTION="refresh"
    shift
    ;;
  --output)
    OUTPUT="${2:-}"
    ACTION="render"
    shift 2
    ;;
  --output-file)
    OUTPUT_FILE="${2:-}"
    shift 2
    ;;
  doctor)
    [[ "${2:-}" == "Raymon" ]] && ACTION="doctor" || ACTION="unknown"
    shift
    ;;
  checkup)
    ACTION="checkup"
    shift
    ;;
  --version)
    echo "raymon-brews v$VERSION"
    exit 0
    ;;
  --help)
    cat <<EOF
🧠 brew_brain v$VERSION – Manage your Raymon Homebrew CLI arsenal

USAGE:
  ./brew_brain.sh [COMMAND] [OPTIONS]

COMMANDS:
  --refresh              🔄 Fetch latest versions of installed Raymon CLIs
  checkup                🩺 Compare installed CLIs against config (see: --config)
  --output FORMAT        📤 Output in alternate formats:
                           - md | markdown : Markdown table
                           - json          : JSON array
                           - table         : Simple CLI table
  --output-file NAME     📝 Write output to NAME.(md|json|txt) depending on --output
  --version              📌 Print current version
  --help                 📖 Show this help message

OPTIONS:
  --silent               🤫 Suppress all interactive or verbose output
  --config PATH          🔧 Use custom config file (default: .brew_brain.json)

EXAMPLE CONFIG (~/.config/brew_brain/.brew_brain.json):
{
  "expected": [
    "bump-version-cli",
    "commit-gh-cli",
    "folder-tree-cli"
  ],
  "install_command": "brew install raymonepping/{formula}"
}

EXAMPLES:
  ./brew_brain.sh --refresh
  ./brew_brain.sh checkup
  ./brew_brain.sh --output markdown
  ./brew_brain.sh --config ./my_config.json
  ./brew_brain.sh --output json --output-file mybrews
EOF
    exit 0
    ;;
  *)
    shift
    ;;
  esac
done

get_installed_brews

case "$ACTION" in
refresh)
  run_refresh
  ;;
doctor)
  run_doctor
  ;;
checkup)
  run_checkup
  ;;
render)
  case "$OUTPUT" in
  md | markdown)
    if [[ -n "$OUTPUT_FILE" ]]; then
      render_markdown >"${OUTPUT_FILE}.md"
      echo "📄 Markdown written to: ${OUTPUT_FILE}.md"
    else
      render_markdown
    fi
    ;;
  json)
    if [[ -n "$OUTPUT_FILE" ]]; then
      render_json >"${OUTPUT_FILE}.json"
      echo "📄 JSON written to: ${OUTPUT_FILE}.json"
    else
      render_json
    fi
    ;;
  table)
    if [[ -n "$OUTPUT_FILE" ]]; then
      render_table >"${OUTPUT_FILE}.txt"
      echo "📄 Table output written to: ${OUTPUT_FILE}.txt"
    else
      render_table
    fi
    ;;
  *)
    echo "❌ Unknown output format: $OUTPUT"
    exit 1
    ;;
  esac
  ;;
*)
  render_human
  ;;
esac
