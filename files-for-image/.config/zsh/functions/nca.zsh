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

  # Helper function to quote path if needed
  local quoted_path
  if [[ "$selection" =~ [[:space:]] ]] || [[ "$selection" =~ [\$\`\\\"\'] ]]; then
    quoted_path="\"$selection\""
  else
    quoted_path="$selection"
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
