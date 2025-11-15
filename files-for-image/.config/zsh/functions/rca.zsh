rca() {
  # rca - fuzzy-find with rg + fzf (content search, including hidden files) and open in $EDITOR
  # Usage:
  #   rca [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all content)
  #   directory   optional directory to search in (defaults to current directory)
  # Features:
  #   - Multi-selection: Use Tab to select multiple files, Shift+Tab to deselect

  setopt local_options pipefail

  _rg_fzf -a -m -c rca "$@"
  local ret=$?
  if [ "$ret" -ne 0 ]; then
    return $ret
  fi

  local selections="$REPLY"

  # no selection was made
  if [ -z "$selections" ]; then
    return 130
  fi

  # Process selections (could be one or multiple)
  local -a file_positions=()
  local -a files=()
  local selection file part_line part_col file_and_pos

  while IFS= read -r selection; do
    # Extract file:line (and column if available)
    # selection format: file:line:column:match...  (column may be absent)
    file="$(printf '%s' "$selection" | awk -F: '{print $1}')"
    part_line="$(printf '%s' "$selection" | awk -F: '{print $2}')"
    part_col="$(printf '%s' "$selection" | awk -F: '{print $3}')"

    if [[ "$EDITOR" == "code" ]]; then
      # build file:line or file:line:column
      if [ -n "$part_col" ] && [ "$part_col" != "" ]; then
        file_and_pos="$file:$part_line:$part_col"
      else
        file_and_pos="$file:$part_line"
      fi
      file_positions+=("$file_and_pos")
    else
      files+=("$file")
    fi
  done <<< "$selections"

  if [[ "$EDITOR" == "code" ]]; then
    # Build command for history
    local cmd="code --reuse-window --goto"
    for pos in "${file_positions[@]}"; do
      if [[ "$pos" =~ [[:space:]] ]] || [[ "$pos" =~ [\$\`\\\"\'] ]]; then
        cmd="$cmd \"$pos\""
      else
        cmd="$cmd $pos"
      fi
    done
    print -s "$cmd"

    # Open all files in VS Code
    code --reuse-window --goto "${file_positions[@]}"
  else
    # $EDITOR doesn't support goto syntax, just open the files
    local editor_cmd="${EDITOR:-nano}"

    # Build command for history
    local cmd="$editor_cmd"
    for file in "${files[@]}"; do
      if [[ "$file" =~ [[:space:]] ]] || [[ "$file" =~ [\$\`\\\"\'] ]]; then
        cmd="$cmd \"$file\""
      else
        cmd="$cmd $file"
      fi
    done
    print -s "$cmd"

    # Open all files
    ${EDITOR:-nano} "${files[@]}"
  fi
  return $?
}
