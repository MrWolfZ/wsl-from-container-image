# Performant direnv counter segment for powerlevel10k
# Shows number of environment variables exported by direnv

# Parse direnv output to count exported variables
_direnv_count_compute() {
  command -v direnv &>/dev/null || return 0

  # Run direnv and capture stdout (the actual export statements)
  local output=$(direnv exec / direnv export zsh 2>/dev/null)

  # Count export statements, excluding DIRENV_* internal variables
  if [[ -n "$output" ]]; then

    # Count total 'export' occurrences
    total=$(grep -o '\bexport\b' <<< "$output" | wc -l)

    # Count excluded ones that start with 'export DIRENV_'
    excluded=$(grep -o '\bexport DIRENV_[A-Za-z0-9_]*' <<< "$output" | wc -l)

    # Compute valid count
    count=$((total - excluded))

    echo "$count"
  else
    echo 0
  fi
}

# Powerlevel10k segment function
prompt_direnv_count() {
  local count=$(_direnv_count_compute)

  # Only show if count > 0
  if (( count > 0 )); then
    p10k segment -f 28 -i '🌿' -t "$count"
  fi
}

# Instant prompt compatibility: define a placeholder function that p10k can cache
typeset -g _p10k__segment_val_direnv_count=
function _p10k_prompt_direnv_count_init() {
  # This function is called by p10k during instant prompt initialization
  # We compute the value once and cache it
  _p10k__segment_val_direnv_count=$(_direnv_count_compute)
}
