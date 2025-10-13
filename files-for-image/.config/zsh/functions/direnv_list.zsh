# List currently exported direnv environment variables
function direnv_list() {
  # Check if direnv is active in current directory
  if [[ -z "$DIRENV_DIR" ]]; then
    echo "direnv is not active in this directory" >&2
    return 1
  fi

  local show_values=0

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case $1 in
    -v)
      show_values=1
      shift
      ;;
    *)
      echo "Usage: direnv_list [-v]" >&2
      echo "  -v  Show variable names and values" >&2
      return 1
      ;;
    esac
  done

  # Get direnv exported variables as JSON
  local direnv_vars
  direnv_vars=$(direnv exec / direnv export json 2>/dev/null) || {
    echo "Failed to get direnv environment" >&2
    return 1
  }

  # Parse JSON and display variables (filter out DIRENV_* variables)
  if ((show_values)); then
    # Get default PATH from a clean shell in $HOME (no direnv)
    local default_path
    default_path=$(cd "$HOME" 2>/dev/null && echo $PATH)

    # Get PATH from direnv if it exists
    local direnv_path
    direnv_path=$(echo "$direnv_vars" | jq -r '.PATH // empty')

    # Collect all output lines
    local -a output_lines

    # Add all non-PATH variables
    while IFS= read -r line; do
      [[ -n "$line" ]] && output_lines+=("$line")
    done < <(echo "$direnv_vars" | jq -r 'to_entries | .[] | select(.key | startswith("DIRENV_") | not) | select(.key != "PATH") | "\(.key)=\(.value)"')

    # Handle PATH specially if it exists
    if [[ -n "$direnv_path" && -n "$default_path" ]]; then
      # Split paths into arrays
      local -a default_entries=(${(s/:/)default_path})
      local -a direnv_entries=(${(s/:/)direnv_path})

      # Convert to associative arrays for easier lookup and deduplication
      local -A default_set
      for entry in "${default_entries[@]}"; do
        default_set[$entry]=1
      done

      local -A direnv_set
      for entry in "${direnv_entries[@]}"; do
        direnv_set[$entry]=1
      done

      # Find additions (in direnv but not in default) - iterate through keys to avoid duplicates
      for entry in "${(@k)direnv_set}"; do
        if [[ ! -v default_set[$entry] ]]; then
          output_lines+=("PATH+=$entry")
        fi
      done

      # Find removals (in default but not in direnv) - iterate through keys to avoid duplicates
      for entry in "${(@k)default_set}"; do
        if [[ ! -v direnv_set[$entry] ]]; then
          output_lines+=("PATH-=$entry")
        fi
      done
    fi

    # Sort and print all lines
    printf '%s\n' "${output_lines[@]}" | sort
  else
    # Show names only
    echo "$direnv_vars" | jq -r 'keys[] | select(startswith("DIRENV_") | not)' | sort
  fi
}
