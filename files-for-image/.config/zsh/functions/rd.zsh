rd() {
  # rd - fuzzy-find with rg + fzf (content search) and navigate to containing directory
  # Usage:
  #   rd [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all content)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _rg_fzf -c rd "$@"
  local ret=$?
  if [ "$ret" -ne 0 ]; then
    return $ret
  fi

  local selection="$REPLY"

  # no selection was made
  if [ -z "$selection" ]; then
    return 130
  fi

  # Extract file path from content search result
  local filepath
  filepath="$(printf '%s' "$selection" | awk -F: '{print $1}')"

  local directory=$(dirname "$filepath")

  # Add to history with proper quoting
  if [[ "$directory" =~ [[:space:]] ]] || [[ "$directory" =~ [\$\`\\\"\'] ]]; then
    print -s "d \"$directory\""
  else
    print -s "d $directory"
  fi

  z $directory

  return $?
}
