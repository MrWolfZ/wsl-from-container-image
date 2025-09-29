re() {
  # re - fuzzy-find with rg + fzf (content search) and open in $EDITOR
  # Usage:
  #   re [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all content)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _rg_fzf -c re "$@"
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
    # build file:line or file:line:column
    if [ -n "$part_col" ] && [ "$part_col" != "" ]; then
      file_and_pos="$file:$part_line:$part_col"
    else
      file_and_pos="$file:$part_line"
    fi

    code --reuse-window --goto "$file_and_pos"
  else
    # $EDITOR doesn't support goto syntax, just open the file
    ${EDITOR:-nano} "$file"
  fi
  return $?
}
