nca() {
  # nca - fuzzy-find with fd + fzf (filename search, including hidden files) and open in $EDITOR
  # Usage:
  #   nca [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all files)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _fd_fzf -a -c nca "$@"
  local ret=$?
  if [ "$ret" -ne 0 ]; then
    return $ret
  fi

  local selection="$REPLY"

  # no selection was made
  if [ -z "$selection" ]; then
    return 130
  fi

  # Convert to relative path for history
  local rel_path=$(realpath --relative-to="$PWD" "$selection" 2>/dev/null || echo "$selection")

  # Helper function to quote path if needed
  local quoted_path
  if [[ "$rel_path" =~ [[:space:]] ]] || [[ "$rel_path" =~ [\$\`\\\"\'] ]]; then
    quoted_path="\"$rel_path\""
  else
    quoted_path="$rel_path"
  fi

  if [[ -f "$selection" ]]; then
    if [[ "$EDITOR" == "code" ]]; then
      print -s "code --reuse-window $quoted_path"
      code --reuse-window "$selection"
    else
      local editor_cmd="${EDITOR:-nano}"
      print -s "$editor_cmd $quoted_path"
      ${EDITOR:-nano} "$selection"
    fi
  else
    print -s "code $quoted_path"
    code "$selection"
  fi

  return $?
}
