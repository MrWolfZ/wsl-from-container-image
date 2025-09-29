# Lock ~/.local/bin directory (make read-only, root-owned)
# This function:
# - Changes ownership of all files in ~/.local/bin to root:root
# - Sets directory permissions to 755 (read-only for non-root)
function lock_local_bin() {
  local bin_dir="$HOME/.local/bin"

  if [[ ! -d "$bin_dir" ]]; then
    echo "${COLOR_RED}Error: ${COLOR_YELLOW}$bin_dir${COLOR_RED} does not exist${COLOR_RESET}" >&2
    return 1
  fi

  echo "Locking ${COLOR_YELLOW}$bin_dir${COLOR_RESET} (setting to root-owned, read-only)..."

  # Change ownership of all files to root
  sudo chown -R root:root "$bin_dir" || return 1

  # Set directory permissions to 755 (rwxr-xr-x)
  sudo chmod 755 "$bin_dir" || return 1

  echo "${COLOR_GREEN}✓${COLOR_RESET} ${COLOR_YELLOW}$bin_dir${COLOR_RESET} is now locked (${COLOR_DARK_CYAN}755${COLOR_RESET}, root-owned)"
}
