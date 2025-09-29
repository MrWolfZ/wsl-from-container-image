# Unlock ~/.local/bin directory (make writable)
# This function:
# - Sets directory permissions to 777 (world-writable)
# - Allows non-root users to write to the directory
function unlock_local_bin() {
  local bin_dir="$HOME/.local/bin"

  if [[ ! -d "$bin_dir" ]]; then
    echo "${COLOR_RED}Error: ${COLOR_YELLOW}$bin_dir${COLOR_RED} does not exist${COLOR_RESET}" >&2
    return 1
  fi

  echo "Unlocking ${COLOR_YELLOW}$bin_dir${COLOR_RESET} (setting to world-writable)..."

  # Set directory permissions to 777 (rwxrwxrwx)
  sudo chmod 777 "$bin_dir" || return 1

  echo "${COLOR_GREEN}✓${COLOR_RESET} ${COLOR_YELLOW}$bin_dir${COLOR_RESET} is now unlocked (${COLOR_DARK_CYAN}777${COLOR_RESET})"
  echo "${COLOR_PURPLE}  Remember to run 'lock_local_bin' when done to secure the directory${COLOR_RESET}"
}
