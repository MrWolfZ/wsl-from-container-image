_fd_fzf() {
  # _fd_fzf - fuzzy-find file paths with fd + fzf
  # Usage:
  #   _fd_fzf [-a] [-c <command_name>] [pattern] [directory]
  # Options:
  #   -a  include hidden files
  #   -c  the name of the calling command to show in messages
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all files)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  local include_hidden=false command_name="_fd_fzf"
  local OPTIND opt

  while getopts "ac:" opt; do
    case "$opt" in
      a) include_hidden=true ;;
      c) command_name=$OPTARG ;;
      *) ;;
    esac
  done
  shift $((OPTIND - 1))

  # helper for red error
  _err() { printf '\e[31m%s\e[0m\n' "$*" >&2; }

  local pattern="$1"
  local search_dir="${2:-.}"

  local hidden_opt=""
  if $include_hidden ; then
    hidden_opt="--hidden"
  fi

  # If pattern is empty, skip initial match check and go straight to fzf
  if [ -z "$pattern" ]; then
    # No pattern: run fd for all files and let fzf handle filtering
    local selection
    selection="$(fd $hidden_opt --color=always . "$search_dir" \
      | fzf --reverse --ansi --preview 'if [ -d {} ]; then eza --color=always --icons=always --group-directories-first --long --all --git {}; else bat --color=always --style=numbers,changes --line-range :500 {}; fi')"

    local ret=$?

    # user cancelled fzf
    if [ "$ret" -ne 0 ]; then
      REPLY=
      return $ret
    fi

    REPLY="$selection"
    return 0
  fi

  # Run fd pipeline and capture results (limit to 2 for performance)
  local results
  results="$(fd $hidden_opt --max-results=2 "$pattern" "$search_dir" 2>/dev/null)"

  if [ -z "$results" ]; then
    _err "$command_name: no files matched the pattern"
    return 3
  fi

  # Count number of results (max 2)
  local count
  count="$(printf '%s\n' "$results" | wc -l)"

  # If only one result, return it directly
  if [ "$count" -eq 1 ]; then
    REPLY="$results"
    return 0
  fi

  # Multiple results: run through fzf with preview
  local selection
  selection="$(fd $hidden_opt --color=always . "$search_dir" \
    | fzf --reverse --ansi --query="$pattern" --preview 'if [ -d {} ]; then eza --color=always --icons=always --group-directories-first --long --all --git {}; else bat --color=always --style=numbers,changes --line-range :500 {}; fi')"

  local ret=$?

  # user cancelled fzf
  if [ "$ret" -ne 0 ]; then
    REPLY=
    return $ret
  fi

  REPLY="$selection"
  return $?
}
