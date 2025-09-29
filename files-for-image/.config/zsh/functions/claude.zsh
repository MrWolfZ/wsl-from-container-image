claude() {
  if [ -f "$PWD/.bin/claude" ]; then
    "$PWD/.bin/claude" "$@"
  else
    echo "no claude cli entrypoint found relative to working directory"
    return 1
  fi
}
