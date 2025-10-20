# --------- initialize direnv and instant prompt ----------
source $ZDOTDIR/p10k_segments/direnv_count.zsh

[ -f $HOME/.local/bin/direnv ] && emulate zsh -c "$($HOME/.local/bin/direnv export zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[ -f $HOME/.local/bin/direnv ] && emulate zsh -c "$($HOME/.local/bin/direnv hook zsh)"

# --------- zsh customization from third party ----------
  # a bunch of settings inspired by https://olets.dev/posts/my-zshrc-zsh-configuration-annotated/

  # Autoloads
    # run-help is like man for builtins
    autoload run-help
    # but!
    # "run-help is normally aliased to man."
    # https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
    # so remove the alias (if there was no alias, suppress the error output)
    unalias run-help 2>/dev/null

  # zsh parameters
    # "Turns on interactive comments; comments begin with a #."
    # https://zsh.sourceforge.io/Intro/intro_16.html
    #
    # That is, enable comments in the terminal. Nice when copying and
    # pasting from documentation/tutorials, and disable part of
    # a command pulled up from history.
    setopt interactivecomments

    # "Beep on an ambiguous completion. More accurately, this forces the
    # completion widgets to return status 1 on an ambiguous completion,
    # which causes the shell to beep if the option BEEP is also set; this
    # may be modified if completion is called from a user-defined widget."
    # https://zsh.sourceforge.io/Doc/Release/Options.html#Completion-4
    unsetopt list_beep

    # "If set, parameter expansion, command substitution and arithmetic
    # expansion are performed in prompts. Substitutions within prompts do
    # not affect the command status."
    # https://zsh.sourceforge.io/Doc/Release/Options.html#Prompting
    setopt prompt_subst

    # zsh zle
    # "The line editor has the ability to highlight characters or
    # regions of the line that have a particular significance. This is
    # controlled by the array parameter zle_highlight, if it has been set
    # by the user."
    # https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Description-6
    # "[paste:] Following a command to paste text, the characters that
    # were inserted."
    # "[none:] No highlighting is applied to the given context. It is not
    # useful for this to appear with other types of highlighting; it is
    # used to override a default."
    # https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting
    #
    # I disable the highlighting of text pasted into the terminal.
    zle_highlight=('paste:none')

# --------- Basic zsh initialization ----------
  export EDITOR="${EDITOR:-micro}"
  export GIT_EDITOR="$EDITOR"

  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  export TERM=xterm-256color

  # define color constants for simple re-use across functions
  export COLOR_BLACK="\033[0;30m"
  export COLOR_DARK_GRAY="\033[1;30m" # looks bold
  export COLOR_RED="\033[0;31m"
  export COLOR_LIGHT_RED="\033[1;31m" # looks bold
  export COLOR_GREEN="\033[0;32m"
  export COLOR_LIGHT_GREEN="\033[1;32m" # looks bold
  export COLOR_YELLOW="\033[0;33m"
  export COLOR_LIGHT_YELLOW="\033[1;33m" # looks bold
  export COLOR_BLUE="\033[0;34m"
  export COLOR_LIGHT_BLUE="\033[1;34m" # looks bold
  export COLOR_PURPLE="\033[0;35m"
  export COLOR_MAGENTA="\033[1;35m" # looks bold
  export COLOR_CYAN="\033[0;36m"
  export COLOR_LIGHT_CYAN="\033[1;36m" # looks bold
  export COLOR_LIGHT_GRAY="\033[0;37m"
  export COLOR_WHITE="\033[1;37m" # looks bold

  export COLOR_RESET="\033[0m"

  # test colors with
  # echo "${COLOR_BLACK}COLOR_BLACK\n${COLOR_DARK_GRAY}COLOR_DARK_GRAY\n${COLOR_RED}COLOR_RED\n${COLOR_LIGHT_RED}COLOR_LIGHT_RED\n${COLOR_GREEN}COLOR_GREEN\n${COLOR_LIGHT_GREEN}COLOR_LIGHT_GREEN\n${COLOR_YELLOW}COLOR_YELLOW\n${COLOR_BRIGHT_YELLOW}COLOR_BRIGHT_YELLOW\n${COLOR_BLUE}COLOR_BLUE\n${COLOR_LIGHT_BLUE}COLOR_LIGHT_BLUE\n${COLOR_PURPLE}COLOR_PURPLE\n${COLOR_MAGENTA}COLOR_MAGENTA\n${COLOR_DARK_CYAN}COLOR_DARK_CYAN\n${COLOR_CYAN}COLOR_CYAN\n${COLOR_LIGHT_GRAY}COLOR_LIGHT_GRAY\n${COLOR_WHITE}COLOR_WHITE\n${COLOR_RESET}COLOR_RESET"

# --------- Source Antidote ----------
  # we need to set the zstyle before loading the ez-compinit plugin
  # Available completion styles: gremlin, ohmy, prez, zshzoo
  # You can add your own too. To see all available completion styles
  # run 'compstyle -l'
  zstyle ':plugin:ez-compinit' 'compstyle' 'zshzoo'

  source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh
  antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt

  # fzf-tab configuration overrides (must be after antidote load)
  # Override zshzoo's 'menu select' to allow fzf-tab to work
  zstyle ':completion:*' menu no

  # Override all format strings with clean bracket format (fzf-tab ignores color codes)
  # These override zshzoo's colored formats which would show as literal %F{color} text in fzf
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':completion:*:corrections' format '[%d (errors: %e)]'
  zstyle ':completion:*:messages' format '[%d]'
  zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
  zstyle ':completion:*' format '[%d]'

  # fzf-tab: disable sort for git checkout to preserve chronological branch order
  zstyle ':completion:*:git-checkout:*' sort false

  # fzf-tab: preview directory contents with eza when completing cd
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --long --group-directories-first --icons=always --color=always $realpath'

  # fzf-tab: full-height interface with reverse layout and border
  zstyle ':fzf-tab:*' fzf-flags --height=100% --layout=reverse --border

  # fzf-tab: switch between completion groups using '<' and '>'
  zstyle ':fzf-tab:*' switch-group '<' '>'

# --------- Powerlevel10k custom segments ----------
  source "${ZDOTDIR:-$HOME}/p10k_segments/direnv_count.zsh"
  source "${ZDOTDIR:-$HOME}/p10k_segments/git_commit.zsh"

# --------- Powerlevel10k config file ----------
  [[ -f "${ZDOTDIR:-$HOME}/.p10k.zsh" ]] && source "${ZDOTDIR:-$HOME}/.p10k.zsh"

# --------- zsh completions ----------

  fpath=(${ZDOTDIR:-$HOME}/completions $fpath)

  # compinit was already called by the ez-compinit plugin, but we also want
  # to support bash completions
  autoload -U +X bashcompinit && bashcompinit

  ## unfortunately the azure CLI does not provide zsh completions out of the box
  [ -f ${ZDOTDIR:-$HOME}/bash_completions/az.completion ] && source ${ZDOTDIR:-$HOME}/bash_completions/az.completion

  ## vault and mc use posener/complete which provides bash-style completions
  [ -f ${ZDOTDIR:-$HOME}/bash_completions/vault.completion ] && source ${ZDOTDIR:-$HOME}/bash_completions/vault.completion
  [ -f ${ZDOTDIR:-$HOME}/bash_completions/mc.completion ] && source ${ZDOTDIR:-$HOME}/bash_completions/mc.completion

  # tweak some completion settings
    # save LS_COLORS before it gets unset for eza (needed for fzf-tab file colorization)
    typeset -g _SAVED_LS_COLORS="$LS_COLORS"

    # set matching behavior to hyphen-insensitive mode like oh-my-zsh
    # see https://github.com/ohmyzsh/ohmyzsh/blob/d57775d89e15687b87eef990b864492d6c973238/lib/completion.zsh#L21
    zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*'

    # This style defines the path where any cache files containing dumped
    # completion data are stored.
    # https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Standard-Styles
    #
    # h/t Marlon Richert for the path
    # https://github.com/marlonrichert/zsh-autocomplete/blob/cfc3fd9a75d0577aa9d65e35849f2d8c2719b873/Functions/Init/.autocomplete__config#L10C24-L10C69
    zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache

    # "If [use-cache] is set, the completion caching layer is activated for
    # any completions which use it"
    # https://zsh.sourceforge.io/Doc/Release/Completion-System.html#index-use_002dcache_002c-completion-style
    # "so that commands like apt and dpkg complete are useable"
    # https://github.com/ohmyzsh/ohmyzsh/blob/01a955657408c8396fc947075a912ee868d5e2a7/lib/completion.zsh#L43C15-L43C70
    zstyle ':completion::complete:*' use-cache yes

    # restore LS_COLORS for completion (fzf-tab needs this for file colorization)
    export LS_COLORS="$_SAVED_LS_COLORS"
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# --------- zsh customization ----------

  # configure history
    # "The file to save the history in when an interactive shell exits."
    # https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell
    HISTFILE="$ZDOTDIR/.zsh_history"

    # "The maximum number of events stored in the internal history list."
    # https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell
    HISTSIZE=1100000000

    # "The maximum number of history events to save in the history file."
    # https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell
    SAVEHIST=1000000000

    # "If the internal history needs to be trimmed to add the current
    # command line, setting this option will cause the oldest history
    # event that has a duplicate to be lost before losing a unique event
    # from the list."
    # https://zsh.sourceforge.io/Doc/Release/Options.html#History
    setopt hist_expire_dups_first

    # "When searching for history entries in the line editor, do not
    # display duplicates of a line previously found, even if the
    # duplicates are not contiguous."
    # https://zsh.sourceforge.io/Doc/Release/Options.html#History
    setopt hist_find_no_dups

    # "Remove command lines from the history list when the first character
    # on the line is a space, or when one of the expanded aliases contains
    # a leading space. Only normal aliases (not global or suffix aliases)
    # have this behavior. Note that the command lingers in the internal
    # history until the next command is entered before it vanishes,
    # allowing you to briefly reuse or edit the line. If you want to make
    # it vanish right away without entering another command, type a space
    # and press return."
    # https://zsh.sourceforge.io/Doc/Release/Options.html#History
    setopt hist_ignore_space

    # "This option both imports new commands from the history file, and
    # also causes your typed commands to be appended to the history file
    # (the latter is like specifying INC_APPEND_HISTORY, which should be
    # turned off if this option is in effect). The history lines are also
    # output with timestamps ala EXTENDED_HISTORY (which makes it easier
    # to find the spot where we left off reading the file after it gets
    # re-written)."
    # https://zsh.sourceforge.io/Doc/Release/Options.html#History
    setopt share_history

  # zsh-autosuggestions plugin
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE='50' # only show suggestions when the command is less than 50 characters long
    ZSH_AUTOSUGGEST_MANUAL_REBIND='false' # can be set to true for better performance, but has caused random error messages for me
    ZSH_AUTOSUGGEST_HISTORY_IGNORE="?(#c200,)" # ignore history entries that are longer than 200 characters
    ZSH_AUTOSUGGEST_STRATEGY=(history) # for performance reasons we only auto-complete with the history instead of additional options like completions

    # This speeds up pasting w/ zsh-autosuggestions and zsh-syntax-highlighting
    # https://github.com/zsh-users/zsh-autosuggestions/issues/238
    # https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
    # pasteinit() {
    #   OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
    #   zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
    # }

    # pastefinish() {
    #   zle -N self-insert $OLD_SELF_INSERT
    # }

    # zstyle :bracketed-paste-magic paste-init pasteinit
    # zstyle :bracketed-paste-magic paste-finish pastefinish
    # end paste speed up

  # set up keybindings
    key[Home]="${terminfo[khome]}"
    key[End]="${terminfo[kend]}"
    key[Insert]="${terminfo[kich1]}"
    key[Backspace]="${terminfo[kbs]}"
    key[Delete]="${terminfo[kdch1]}"
    key[Up]="${terminfo[kcuu1]}"
    key[Down]="${terminfo[kcud1]}"
    key[Left]="${terminfo[kcub1]}"
    key[Right]="${terminfo[kcuf1]}"
    key[PageUp]="${terminfo[kpp]}"
    key[PageDown]="${terminfo[knp]}"
    key[Shift-Tab]="${terminfo[kcbt]}"

    # use emacs by default
    bindkey -e

    # do not consider any special characters as words characters
    # the default would be something like *?_-.[]~=/&;!#$%^(){}<>
    WORDCHARS=''

    # zsh-history-substring-search plugin
      # there is an incompatibility when searching at the beginning of a command
      # with a visible auto-suggestion, where after the history search is performed,
      # the autosuggestion is still shown; as a workaround, below we define custom
      # functions which temporarily disable the autosuggest plugin when searching
      # the history; it also fixes a problem with ghost suggestions when navigating
      # through the history

      _history_substring_search_up() {
        zle autosuggest-disable
        zle history-substring-search-up

        # schedule a tiny non-blocking re-enable (0.02s), reset prompt (-p),
        # and invalidate suggestions (-s)
        zsh-defer -t 0.02 -p -s zle autosuggest-enable
      }

      zle -N _history_substring_search_up

      _history_substring_search_down() {
        zle autosuggest-disable
        zle history-substring-search-down

        zsh-defer -t 0.02 -p -s zle autosuggest-enable
      }

      zle -N _history_substring_search_down

      [[ -n "${key[Up]}" ]] && bindkey -- "${key[Up]}" _history_substring_search_up
      [[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" _history_substring_search_down

    # [Shift-Tab] - move through the completion menu backwards
    [[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}" reverse-menu-complete

    # [Ctrl-RightArrow] - move forward one word
    bindkey '^[[1;5C' forward-word

    # [Ctrl-LeftArrow] - move backward one word
    bindkey '^[[1;5D' backward-word

    # [Ctrl-Backspace] - delete whole word
    bindkey '^W' backward-delete-word
    
      # in Windows Terminal the key code for Ctrl-Backspace is different
      # for some reason so we need to define another key binding
      bindkey '^H' backward-delete-word

    # [Ctrl-Delete] - delete whole word forward
    bindkey '^[d' delete-word
    
      # in Windows Terminal the key code for Ctrl-Backspace is different
      # for some reason so we need to define another key binding
      bindkey '^[[3;5~' delete-word

# --------- user customization ----------

  # modify PATH
    # deduplicate any entries in $PATH
    typeset -U path PATH

    path=(
      "$HOME/.local/bin"
      "$HOME/go/bin"
      "$HOME/.golang/bin"
      "$HOME/.cargo/bin"
      $path
      "$HOME/.dotnet/tools"
    )

    export PATH

  # configure fnm (Fast Node Manager)
    if command -v fnm &> /dev/null; then
      eval "$(fnm env --use-on-cd)"
    fi

    # custom override for the npm command to sandbox installs
    source "$ZDOTDIR/functions/npm.zsh"

    # set some sensible environment variables for NPM
    export npm_config_fund='false'

  # configure uv/pip sandboxing
    # custom overrides for uv and pip commands to sandbox installs
    source "$ZDOTDIR/functions/uv.zsh"
    source "$ZDOTDIR/functions/pip.zsh"

  # configure dotnet
    export DOTNET_CLI_TELEMETRY_OPTOUT='1'
    export MSBUILDSINGLELOADCONTEXT='1'

  # configure java
    export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

  # configure podman
    export PODMAN_COMPOSE_PROVIDER='podman-compose'
    export DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"

  # configure cloud tools
    export USE_GKE_GCLOUD_AUTH_PLUGIN='True'

  # set up navigation and search functionality
    # set up fzf key bindings
    source "$ZDOTDIR/fzf.zsh"

    # di - fuzzy-find with zoxide + fzf and navigate to directory
    source "$ZDOTDIR/functions/di.zsh"

    # alias zoxide to d (because it is easier to access and it is a nice mnemonic for 'directory')
    alias d=z

    # create a common alias for 'ls', although with this setup it is preferable to always use the 't' aliases below
    alias ll='ls -alhov --color --group-directories-first'

    EZA_COMMAND='eza --all --long --group-directories-first --header --icons=always --smart-group --time-style long-iso --no-time --tree --level'
    alias t="$EZA_COMMAND 1"
    alias t2="$EZA_COMMAND 2"
    alias t3="$EZA_COMMAND 3"
    alias t4="$EZA_COMMAND 4"

    # reset the LS_COLORS environment variable since it would conflict with our theme for eza
    unset LS_COLORS

    # yd - open yazi TUI and navigate to directory on quit
    source "$ZDOTDIR/functions/yd.zsh"

    # sd - open superfile TUI and navigate to directory on quit
    source "$ZDOTDIR/functions/sd.zsh"

    # _rg_fzf - helper function to fuzzy-find with rg + fzf (content search)
    source "$ZDOTDIR/functions/_rg_fzf.zsh"
    # _fd_fzf - helper function to fuzzy-find with fd + fzf (filename search)
    source "$ZDOTDIR/functions/_fd_fzf.zsh"

    # r - fuzzy-find with rg + fzf (content search) and return file path
    source "$ZDOTDIR/functions/r.zsh"
    # ra - same as r but includes hidden files
    source "$ZDOTDIR/functions/ra.zsh"

    # n - fuzzy-find with fd + fzf (filename search) and return file path
    source "$ZDOTDIR/functions/n.zsh"
    # na - same as n but includes hidden files
    source "$ZDOTDIR/functions/na.zsh"

    # rd - fuzzy-find with rg + fzf (content search) and navigate to directory
    source "$ZDOTDIR/functions/rd.zsh"
    # rda - same as rd but includes hidden files
    source "$ZDOTDIR/functions/rda.zsh"

    # nd - fuzzy-find with fd + fzf (filename search) and navigate to directory
    source "$ZDOTDIR/functions/nd.zsh"
    # nda - same as nd but includes hidden files
    source "$ZDOTDIR/functions/nda.zsh"

    # rc - fuzzy-find with rg + fzf (content search) and open in $EDITOR
    source "$ZDOTDIR/functions/rc.zsh"
    # rca - same as rc but includes hidden files
    source "$ZDOTDIR/functions/rca.zsh"

    # nc - fuzzy-find with fd + fzf (filename search) and open in $EDITOR
    source "$ZDOTDIR/functions/nc.zsh"
    # nca - same as nc but includes hidden files
    source "$ZDOTDIR/functions/nca.zsh"

  # utility functions
    host_ip() {
      ip route show | grep -i default | awk '{ print $3 }'
    }

    # unlock_local_bin - allow writing to "$HOME/.local/bin"
    source "$ZDOTDIR/functions/unlock_local_bin.zsh"

    # lock_local_bin - prevent writing to "$HOME/.local/bin" and change all owners to `root`
    source "$ZDOTDIR/functions/lock_local_bin.zsh"

    # backup - create compressed tarball backup of home directory
    source "$ZDOTDIR/functions/backup.zsh"

    # claude - launch claude code as a container
    source "$ZDOTDIR/functions/claude.zsh"

    # k3s_start - start k3s rootless service
    source "$ZDOTDIR/functions/k3s_start.zsh"

    # k3s_stop - stop k3s rootless service
    source "$ZDOTDIR/functions/k3s_stop.zsh"

    # direnv_list - list direnv-exported environment variables
    source "$ZDOTDIR/functions/direnv_list.zsh"

  # zsh-abbr
    # general configurations: https://zsh-abbr.olets.dev/configuration-variables.html
    ABBR_USER_ABBREVIATIONS_FILE="$ZDOTDIR/.zsh_abbr.cfg"
    ABBR_TMPDIR="$HOME/.cache/zsh/zsh-abbr"

    # configure prefixes: https://zsh-abbr.olets.dev/prefixes.html
    ABBR_REGULAR_ABBREVIATION_SCALAR_PREFIXES=('sudo' 'watch')
    ABBR_REGULAR_ABBREVIATION_GLOB_PREFIXES=()

    # configure cursor placement: https://zsh-abbr.olets.dev/cursor-placement.html
    ABBR_SET_EXPANSION_CURSOR=1
    ABBR_SET_LINE_CURSOR=0

    # enable syntax highlighting with zsh-abbr
    zsh-defer source "$ZDOTDIR/.zsh_abbr_syntax_highlighting.zsh"

    # fix ghost text issue with with zsh-abbr and zsh-autosuggestions
    zsh-defer source "$ZDOTDIR/.zsh_abbr_autosuggestions.zsh"

    # podman
    alias pl="DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock lazydocker"

  # misc aliases
    # a bunch of aliases to safeguard against mistakes
    alias rm='rm -I --preserve-root'
    alias mv='mv -i'
    alias cp='cp -i'
    alias ln='ln -i'
    alias chown='chown --preserve-root'
    alias chmod='chmod --preserve-root'
    alias chgrp='chgrp --preserve-root'

    # when not inside vscode (e.g. when opening wsl from windows terminal) we want
    # to be able to start a vscode instance, so we need to make the windows binary
    # available; however, when running a terminal inside VSCode, the running instance
    # will add its own path to $PATH, so we don't need the windows binary; also, using
    # the native linux binary is significantly faster than using the windows binary
    (( ! $+commands[code] )) && alias code="/mnt/c/Users/dev/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code"

    # enable quickly opening a directory in the windows file explorer
    alias explorer='/mnt/c/Windows/SysWOW64/explorer.exe'

    # enable opening powershell
    alias pwsh='/mnt/c/Program\ Files/Powershell/7/pwsh.exe'

    # the most beautiful command to ever exist
    alias git-delete-untracked-branches="git fetch -p && for branch in \$(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '\$2 == \"[gone]\" {sub(\"refs/heads/\", \"\", \$1); print \$1}'); do git branch -D \$branch; done"

  # final configuration tweaks
    # prefer VS Code if available, otherwise fallback to micro (set earlier in this file)
    (( $+commands[code] )) && export EDITOR='code'
    (( $+commands[code] )) && export GIT_EDITOR="code --wait"

  # git configuration reminder
    # Check if git is properly configured and show reminder if not
    # Uses zsh-defer to avoid interfering with instant prompt
    _check_git_config() {
      local git_name=$(git config --global user.name 2>/dev/null)
      if [[ "$git_name" == "ChangeMe" ]]; then
        echo ""
        echo "💡 Reminder: Configure git properly with your user:"
        echo "   git config --global user.name '<your name>'"
        echo "   git config --global user.email '<your email>'"
        echo ""
        echo "   Remove this reminder by deleting the '# git configuration reminder'"
        echo "   section from ~/.config/zsh/.zshrc"
        echo ""
      fi
    }

    zsh-defer -1 -c '_check_git_config'

  # $HOME/.local/bin unlock reminder
    _check_local_bin_unlocked() {
      if [[ -w "$HOME/.local/bin" ]]; then
        echo ""
        echo "${COLOR_LIGHT_RED}\uf071 ATTENTION: ${COLOR_YELLOW}${HOME}/.local/bin${COLOR_LIGHT_RED} is unlocked${COLOR_RESET}"
        echo ""
      fi
    }

    zsh-defer -1 -c '_check_local_bin_unlocked'
