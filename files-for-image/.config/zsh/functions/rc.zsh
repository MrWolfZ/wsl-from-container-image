rc() {
  # rc - fuzzy-find with rg + fzf (content search) and open in $EDITOR
  # Usage:
  #   rc [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all content)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _rg_fzf -c rc "$@"
  local ret=$?
  if [ "$ret" -ne 0 ]; then
    return $ret
  fi

  local selection="$REPLY"

  # no selection was made
  if [ -z "$selection" ]; then
    return 130
  fi

  # Extract file:line (and column if available) and open in existing window with goto
  # selection format: file:line:column:match...  (column may be absent)
  local file part_line part_col file_and_pos
  file="$(printf '%s' "$selection" | awk -F: '{print $1}')"
  part_line="$(printf '%s' "$selection" | awk -F: '{print $2}')"
  part_col="$(printf '%s' "$selection" | awk -F: '{print $3}')"

  if [[ "$EDITOR" == "code" ]]; then
    # build file:line or file:line:column for both execution and history
    if [ -n "$part_col" ] && [ "$part_col" != "" ]; then
      file_and_pos="$file:$part_line:$part_col"
      local rel_pos="$file:$part_line:$part_col"
    else
      file_and_pos="$file:$part_line"
      local rel_pos="$file:$part_line"
    fi

    # Add to history with proper quoting
    if [[ "$rel_pos" =~ [[:space:]] ]] || [[ "$rel_pos" =~ [\$\`\\\"\'] ]]; then
      print -s "code --reuse-window --goto \"$rel_pos\""
    else
      print -s "code --reuse-window --goto $rel_pos"
    fi

    code --reuse-window --goto "$file_and_pos"
  else
    # $EDITOR doesn't support goto syntax, just open the file
    local editor_cmd="${EDITOR:-nano}"

    # Add to history with proper quoting
    if [[ "$file" =~ [[:space:]] ]] || [[ "$file" =~ [\$\`\\\"\'] ]]; then
      print -s "$editor_cmd \"$file\""
    else
      print -s "$editor_cmd $file"
    fi

    ${EDITOR:-nano} "$file"
  fi
  return $?
}
