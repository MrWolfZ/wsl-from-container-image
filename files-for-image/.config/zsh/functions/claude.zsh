claude() {
  # walk up the directory tree to find a .bin/claude file
  local dir="$PWD"
  local claude_path=""
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.bin/claude" ]; then
      claude_path="$dir/.bin/claude"
      break
    fi
    dir=$(dirname "$dir")
  done

  if [ -f "$claude_path" ]; then
    chmod +x "$claude_path"
    clear
    "$claude_path" "$@"
  else
    echo "no claude cli entrypoint found relative to working directory"
    return 1
  fi
}
