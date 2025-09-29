function yd() {
  # yd - open yazi TUI and navigate to directory on quit
  # Usage:
  #   yd

  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      z -- "$cwd"
  fi
  rm -f -- "$tmp"
}
