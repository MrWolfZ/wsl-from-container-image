nd() {
  # nd - fuzzy-find with fd + fzf (filename search) and navigate to containing directory
  # Usage:
  #   nd [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all files)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _fd_fzf -c nd "$@"
  local ret=$?
  if [ "$ret" -ne 0 ]; then
    return $ret
  fi

  local selection="$REPLY"

  # no selection was made
  if [ -z "$selection" ]; then
    return 130
  fi

  local directory=$(dirname "$selection")
  z $directory

  return $?
}
