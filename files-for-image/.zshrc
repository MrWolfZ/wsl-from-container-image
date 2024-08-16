(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/dev/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  kubetail
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# This speeds up pasting w/ autosuggest and syntax highlighting
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
# https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}

zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish
# end paste speed up

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# environment variables
export GOBIN="$HOME/.local/bin/golang/bin"
export CARGO_BIN="$HOME/.cargo/bin"
LOCAL_BIN="$HOME/.local/bin"
DOTNET_TOOLS="$HOME/.dotnet/tools"
export PATH="$LOCAL_BIN:$GOBIN:$CARGO_BIN:$PATH:$DOTNET_TOOLS"

# define a pager for unpaged git log
export PAGER="less -F"

# deduplicate any entries in $PATH
typeset -U path

export DOTNET_CLI_TELEMETRY_OPTOUT='1'
export MSBUILDSINGLELOADCONTEXT='1'

export DOCKER_SCAN_SUGGEST='false'
export DOCKER_CLI_HINTS='false'

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

export USE_GKE_GCLOUD_AUTH_PLUGIN='True'

export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE='50' # only show suggestions when the command is less than 50 characters long
export ZSH_AUTOSUGGEST_MANUAL_REBIND='false' # can be set to true for better performance, but has caused random error messages for me
export ZSH_AUTOSUGGEST_HISTORY_IGNORE="?(#c200,)" # ignore history entries that are longer than 200 characters

# completion scripts
[ ! -f "$HOME/.zsh_completion_kubectl" ] && kubectl completion zsh > "$HOME/.zsh_completion_kubectl"
source "$HOME/.zsh_completion_kubectl"

source "$HOME/.zsh_completion_kubectx"
source "$HOME/.zsh_completion_kubetail"

source "$HOME/.zsh_completion_just"

source "$HOME/.zsh_completion_az"

# aliases
alias k='kubectl'
alias ll='ls -alh --color=auto'
alias kubectx=$ZSH/custom/plugins/kubectx/kubectx
alias kubens=$ZSH/custom/plugins/kubectx/kubens
alias python=python3
alias code=/mnt/c/tools/VSCode/bin/code
alias lazypodman='DOCKER_HOST=unix:///run/user/1000/podman/podman.sock lazydocker'
