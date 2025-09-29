ra() {
  # ra - fuzzy-find with rg + fzf (content search, including hidden files) and print file path
  # Usage:
  #   ra [pattern] [directory]
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all content)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  _rg_fzf -a -c ra "$@"
  local ret=$?
  if [ "$ret" -ne 0 ]; then
    return $ret
  fi

  local selection="$REPLY"

  # no selection was made
  if [ -z "$selection" ]; then
    return 130
  fi

  # Extract file path
  local file
  file="$(printf '%s' "$selection" | awk -F: '{print $1}')"

  echo -n "$file"
  return $?
}
