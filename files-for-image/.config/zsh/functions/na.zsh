na() {
  # na - fuzzy-find with fd + fzf (filename search, including hidden files) and print file path
  # Usage:
  #   na [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all files)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _fd_fzf -a -c na "$@"
  local ret=$?
  if [ "$ret" -ne 0 ]; then
    return $ret
  fi

  local selection="$REPLY"

  # no selection was made
  if [ -z "$selection" ]; then
    return 130
  fi

  echo -n "$selection"
  return $?
}
