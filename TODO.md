# TODO

- properly handle ctrl-backspace in micro settings for both windows terminal and vscode
- fix k3s not working
- create function claude-init which initializes the claude cli with a default setup
- clean up builds
  - move neovim to shell-tools layer (where nano and micro are)
  - create build-tools layer
  - create podman variant
  - make the ai and dev variants derive from the podman variant
- put podman binaries into $HOME/.local/bin (including all systemd references)
  - make sure that the systemd service has the above in the PATH
- add ncdu tool for disk space usage analyses
- add tool shfmt
- update list of recommended extensions

- (optional) add podman-tui
- pull tool installations and updates into a dedicated script that can be repeated after import to update tools
- play around with different fonts
- align terminal nav shortcuts (both in vscode as well as windows terminal)
  - ctrl+shift+pgup/pgdown for scroll page
  - ctrl+shift+up/down for scroll line
  - alt+up/down for scrolling to commands
