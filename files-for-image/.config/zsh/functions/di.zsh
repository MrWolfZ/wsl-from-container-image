di() {
  local dest=$(zoxide query --list --score \
    | fzf --layout reverse --info inline --border \
      --preview "eza --all --group-directories-first --header --long --no-user --no-permissions --color=always {2}" \
      --no-sort \
    | awk '{print $2}')
  [[ -n "$dest" ]] && cd "$dest"
}
