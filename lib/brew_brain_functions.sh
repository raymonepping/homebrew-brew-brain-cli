get_installed_brews() {
  local info regex
  readarray -t all < <(brew list --formula 2>/dev/null || true)
  [[ ${#all[@]} -eq 0 ]] && return
  info=$(brew info --json=v2 "${all[@]}" 2>/dev/null)

  # Dynamically build regex from CLI_NAMES array
  regex="^($(IFS=\|; echo "${CLI_NAMES[*]}"))$"

  mapfile -t BREWS < <(echo "$info" | jq -r --arg regex "$regex" '
    .formulae[]? | select(.name | test($regex)) | .name // empty
  ')
}

get_installed_version() {
  brew info --json=v2 "$1" 2>/dev/null | jq -r '.formulae[0].versions.stable // empty'
}

get_latest_version() {
  local brew="$1"

  local repo desc
  repo=$(jq -r --arg name "$brew" '.tools[] | select(.name == $name) | .repo' "$CONFIG_FILE")
  desc=$(jq -r --arg name "$brew" '.tools[] | select(.name == $name) | .description' "$CONFIG_FILE")

  if [[ -z "$repo" || "$repo" == "null" ]]; then
    echo "–"
    return 1
  fi

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

get_description() {
  jq -r --arg name "$1" '.tools[] | select(.name == $name) | .description' "$CONFIG_FILE"
}

render_human() {
  echo "🧠 Raymon's Homebrew CLI Arsenal (${#BREWS[@]} tools)"
  echo "────────────────────────────────────────────────────────────"
  for brew in "${BREWS[@]}"; do
    local_version=$(get_installed_version "$brew")
    latest_version=$(get_latest_version "$brew")
    desc=$(get_description "$brew")
    symbol="✅"
    [[ "$local_version" != "$latest_version" && "$latest_version" != "–" ]] && symbol="⬆️"

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
  local status_tpl="${TPL_DIR}/brew_brain_status.tpl"
  local header_tpl="${TPL_DIR}/brew_brain_header.tpl"
  local summary_tpl="${TPL_DIR}/brew_brain_summary.tpl"
  local table_tpl="${TPL_DIR}/brew_brain_md.tpl"
  local footer_tpl="${TPL_DIR}/brew_brain_footer.tpl"

  local table_rows=""
  local NUM_TOOLS="${#BREWS[@]}"
  local NUM_UP_TO_DATE=0
  local NUM_OUTDATED=0
  local NUM_MISSING=0

  for brew in "${BREWS[@]}"; do
    desc=$(jq -r --arg name "$brew" '.tools[] | select(.name == $name) | .description // "Unknown"' "$CONFIG_FILE")
    ver=$(jq -r --arg name "$brew" '.tools[] | select(.name == $name) | .version // "–"' "$CONFIG_FILE")
    table_rows="${table_rows}| \`$brew\` | $ver | $desc |\n"
  # table_rows="${table_rows}| \$brew\ | $ver | $desc |\n"
  done

  local DATE="$(date '+%Y-%m-%d %H:%M:%S')"
  local NUM_TOOLS="${#BREWS[@]}"

  # Status badges block
  awk -v DATE="$DATE" -v NUM_TOOLS="$NUM_TOOLS" '{gsub(/\{\{DATE\}\}/, DATE); gsub(/\{\{NUM_TOOLS\}\}/, NUM_TOOLS); print}' "$status_tpl"

  # Header block
  awk -v DATE="$DATE" '{gsub(/\{\{DATE\}\}/, DATE); print}' "$header_tpl"

 # Summary block
  awk -v NUM_TOOLS="$NUM_TOOLS" -v NUM_UP_TO_DATE="$NUM_UP_TO_DATE" -v NUM_OUTDATED="$NUM_OUTDATED" -v NUM_MISSING="$NUM_MISSING" '
    {gsub(/\{\{NUM_TOOLS\}\}/, NUM_TOOLS);
     gsub(/\{\{NUM_UP_TO_DATE\}\}/, NUM_UP_TO_DATE);
     gsub(/\{\{NUM_OUTDATED\}\}/, NUM_OUTDATED);
     gsub(/\{\{NUM_MISSING\}\}/, NUM_MISSING);
     print
    }' "$summary_tpl"

  # Main table
  awk -v TABLE_ROWS="$table_rows" '{gsub(/\{\{TABLE_ROWS\}\}/, TABLE_ROWS); print}' "$table_tpl"

  # Footer
  cat "$footer_tpl"
}

render_json() {
  local output_file="${1:-}"
  if [[ -n "$output_file" ]]; then
    {
      echo "["
      local first=1
      for brew in "${BREWS[@]}"; do
        [[ $first -eq 0 ]] && echo ","
        first=0
        desc=$(jq -r --arg name "$brew" '.tools[] | select(.name == $name) | .description // "Unknown"' "$CONFIG_FILE")
        ver=$(jq -r --arg name "$brew" '.tools[] | select(.name == $name) | .version // "–"' "$CONFIG_FILE")
        echo "  { \"name\": \"$brew\", \"version\": \"$ver\", \"description\": \"$desc\" }"
      done
      echo "]"
    } > "$output_file"
    # Now sort and pretty-print in-place
    jq 'sort_by(.name)' "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
    echo "📄 JSON written (sorted & pretty) to: $output_file"
  else
    echo "["
    local first=1
    for brew in "${BREWS[@]}"; do
      [[ $first -eq 0 ]] && echo ","
      first=0
      desc=$(jq -r --arg name "$brew" '.tools[] | select(.name == $name) | .description // "Unknown"' "$CONFIG_FILE")
      ver=$(jq -r --arg name "$brew" '.tools[] | select(.name == $name) | .version // "–"' "$CONFIG_FILE")
      echo "  { \"name\": \"$brew\", \"version\": \"$ver\", \"description\": \"$desc\" }"
    done
    echo "]"
  fi
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