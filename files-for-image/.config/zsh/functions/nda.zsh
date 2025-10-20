nda() {
  # nda - fuzzy-find with fd + fzf (filename search, including hidden files) and navigate to containing directory
  # Usage:
  #   nda [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all files)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _fd_fzf -a -c nda "$@"
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

  # Add to history with proper quoting
  if [[ "$directory" =~ [[:space:]] ]] || [[ "$directory" =~ [\$\`\\\"\'] ]]; then
    print -s "d \"$directory\""
  else
    print -s "d $directory"
  fi

  z $directory

  return $?
}
