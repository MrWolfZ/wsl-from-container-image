rda() {
  # rda - fuzzy-find with rg + fzf (content search, including hidden files) and navigate to containing directory
  # Usage:
  #   rda [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all content)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _rg_fzf -a -c rda "$@"
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

  # Convert to relative path for history
  local rel_dir=$(realpath --relative-to="$PWD" "$directory" 2>/dev/null || echo "$directory")

  # Add to history with proper quoting
  if [[ "$rel_dir" =~ [[:space:]] ]] || [[ "$rel_dir" =~ [\$\`\\\"\'] ]]; then
    print -s "d \"$rel_dir\""
  else
    print -s "d $rel_dir"
  fi

  z $directory

  return $?
}
