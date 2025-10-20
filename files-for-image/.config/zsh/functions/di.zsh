di() {
  local query_args=()
  if [ -n "${1:-}" ]; then
    query_args=(--query "$1")
  fi

  local dest=$(zoxide query --list --score |
    fzf --layout reverse --info inline --border \
      --preview "eza --all --group-directories-first --header --long --no-user --no-permissions --color=always {2}" \
      $query_args \
      --no-sort |
    awk '{print $2}')
  [[ -n "$dest" ]] && cd "$dest"
}
