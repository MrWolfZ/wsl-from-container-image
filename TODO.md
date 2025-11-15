# TODO

- add sandbox functions for `npx` (similar to `npm`) and `uvx` (similar to `uv`) so that scripts that are run with these commands are properly sandboxed
- do more cool stuff with `fzf`
  - see <https://github.com/junegunn/fzf/blob/master/ADVANCED.md> for ideas

- try out having the prompt always at the bottom
  - see also <https://github.com/romkatv/powerlevel10k/issues/563>

- add tool: <https://github.com/asciinema/asciinema>
- add tool: <https://github.com/tsl0922/ttyd>
- add tool: <https://github.com/schollz/croc>
  - see also <https://github.com/toddmcintire/croc-gui> and <https://github.com/howeyc/crocgui>

- create a function `just` that calls just with appropriate shell args to point it to a zsh instance with our custom functions for uv and npm etc. populated
- ensure that sudo has access to micro by symlinking into /usr/bin
- properly handle ctrl-backspace in micro settings for both windows terminal and vscode
- create function claude-init which initializes the claude cli with a default setup
- update list of recommended extensions
- make systemd unit files readonly

- pull tool installations and updates into a dedicated script that can be repeated after import to update tools
- play around with different fonts
- align terminal nav shortcuts (both in vscode as well as windows terminal)
  - ctrl+shift+pgup/pgdown for scroll page
  - ctrl+shift+up/down for scroll line
  - alt+up/down for scrolling to commands

- add README about fonts
  - my recommendation is <https://github.com/banDeveloper/Consolas-Nerd-Font>
  - fonts can be downloaded here: <https://www.nerdfonts.com/font-downloads>
  - fonts can be tried out here: <https://www.programmingfonts.org/#ubuntu>
