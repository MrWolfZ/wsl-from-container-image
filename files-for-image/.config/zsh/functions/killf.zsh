killf() {
  # killf - fuzzy-find user processes and send signal
  # Usage:
  #   killf <signal> [query]
  # Arguments:
  #   signal  required signal to send (e.g., -9, -15, -TERM, -KILL)
  #   query   optional query string to prefilter process list
  # Features:
  #   - Multi-selection: Use Tab to select multiple processes, Shift+Tab to deselect
  #   - Only shows processes owned by current user

  setopt local_options pipefail

  _kill_fzf -c killf "$@"
  local ret=$?
  if [ "$ret" -ne 0 ]; then
    return $ret
  fi

  local reply_data="$REPLY"

  # No selection was made
  if [ -z "$reply_data" ]; then
    return 130
  fi

  # Parse reply: first line is signal, rest are PIDs
  local signal
  local -a pids=()
  local first_line=true

  while IFS= read -r line; do
    if $first_line; then
      signal="$line"
      first_line=false
    else
      pids+=("$line")
    fi
  done <<< "$reply_data"

  if [ ${#pids[@]} -eq 0 ]; then
    printf '\e[31m%s\e[0m\n' "killf: no processes selected" >&2
    return 1
  fi

  # Send signal to all selected PIDs
  echo "Sending signal $signal to ${#pids[@]} process(es): ${pids[*]}"
  kill "$signal" "${pids[@]}"
  return $?
}
