_kill_fzf() {
  # _kill_fzf - fuzzy-find processes with ps + fzf
  # Usage:
  #   _kill_fzf [-a] [-c <command_name>] <signal> [query]
  # Options:
  #   -a  show all processes (not just user's processes)
  #   -c  the name of the calling command to show in messages
  # Arguments:
  #   signal  required signal to send (e.g., -9, -15, -TERM, -KILL)
  #   query   optional query string to prefilter process list

  setopt local_options pipefail

  local all_processes=false command_name="_kill_fzf"

  # Parse only known flags; treat anything else as positional arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -a)
      all_processes=true
      shift
      ;;
    -c)
      if [[ $# -lt 2 ]]; then
        break
      fi
      command_name="$2"
      shift 2
      ;;
    *)
      # Not a recognized flag, stop parsing and treat as positional argument
      break
      ;;
    esac
  done

  # helper for red error
  _err() { printf '\e[31m%s\e[0m\n' "$*" >&2; }

  # Signal is mandatory
  local signal="$1"
  if [ -z "$signal" ]; then
    _err "$command_name: signal is required (e.g., -9, -15, -TERM, -KILL)"
    return 1
  fi
  shift

  local query="${1:-}"

  # Build ps command
  local -a ps_cmd
  if $all_processes; then
    ps_cmd=(ps -e -ww -o pid=,user=,%cpu=,%mem=,cmd= --no-headers)
  else
    ps_cmd=(ps -u "$USER" -ww -o pid=,user=,%cpu=,%mem=,cmd= --no-headers)
  fi

  local fzf_query_opt=""
  if [ -n "$query" ]; then
    fzf_query_opt="--query=$query"
  fi

  # Build ps command string for reload binding
  local ps_cmd_str
  if $all_processes; then
    ps_cmd_str="ps -e -ww -o pid=,user=,%cpu=,%mem=,cmd= --no-headers"
  else
    ps_cmd_str="ps -u \$USER -ww -o pid=,user=,%cpu=,%mem=,cmd= --no-headers"
  fi

  # Build awk program
  local awk_prog='BEGIN { printf "%7s  %-12s  %6s  %6s  %s\n", "PID", "USER", "%CPU", "%MEM", "COMMAND" } { pid = $1; user = $2; cpu = $3; mem = $4; cmd = ""; for(i=5; i<=NF; i++) cmd = cmd (i==5 ? "" : " ") $i; printf "%7s  %-12s  %5s%%  %5s%%  %s\n", pid, user, cpu, mem, cmd }'

  local selected_lines
  selected_lines="$("${ps_cmd[@]}" | \
    awk "$awk_prog" | \
    fzf --multi --header-lines=1 \
        --no-hscroll \
        --ellipsis='...' \
        --bind "ctrl-r:reload($ps_cmd_str | awk $(printf '%q' "$awk_prog"))" \
        $fzf_query_opt \
        --preview='ps -p {1} -ww -o pid,ppid,user,start,time,%cpu,%mem,cmd --no-headers | cat' \
        --preview-window='down:5:wrap')"

  local ret=$?

  # User cancelled fzf
  if [ "$ret" -ne 0 ]; then
    REPLY=
    return $ret
  fi

  # Extract PIDs from selected lines
  local -a pids=()
  local pid
  while IFS= read -r line; do
    # PID is the first field
    pid="$(echo "$line" | awk '{print $1}')"
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
      pids+=("$pid")
    fi
  done <<< "$selected_lines"

  if [ ${#pids[@]} -eq 0 ]; then
    _err "$command_name: no processes selected"
    REPLY=
    return 1
  fi

  # Return PIDs and signal via REPLY for the wrapper to handle
  REPLY="$signal"$'\n'"${(F)pids}"
  return 0
}
