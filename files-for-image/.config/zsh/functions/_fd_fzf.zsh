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
  local no_ignore_opt=""
  if $include_hidden; then
    hidden_opt="--hidden"
    no_ignore_opt="--no-ignore"
  fi

  # Always run fd without filtering and let fzf handle the pattern via --query
  local fzf_query=""
  if [ -n "$pattern" ]; then
    fzf_query="--query=$pattern"
  fi

  local selection
  selection="$(fd $hidden_opt $no_ignore_opt --absolute-path --color=always . "$search_dir" |
    fzf $fzf_query --preview 'if [ -d {} ]; then eza --color=always --icons=always --group-directories-first --long --all --git {}; else bat --color=always --style=numbers,changes --line-range :500 {}; fi')"

  local ret=$?

  # user cancelled fzf
  if [ "$ret" -ne 0 ]; then
    REPLY=
    return $ret
  fi

  REPLY="$selection"
  return 0
}
