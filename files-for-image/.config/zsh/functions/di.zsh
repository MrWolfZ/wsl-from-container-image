di() {
  local query_args=()
  if [ -n "${1:-}" ]; then
    query_args=(--query "$1")
  fi

  local dest=$(zoxide query --list --score |
    fzf "${FZF_ZOXIDE_OPTS_ARR[@]}" $query_args |
    awk '{print $2}')
  [[ -n "$dest" ]] && cd "$dest"
}
