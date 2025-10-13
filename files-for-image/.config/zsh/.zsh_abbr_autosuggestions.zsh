# fix ghost text issue with zsh-autosuggestions
# when an abbreviation is expanded, the autosuggestion ghost text remains visible
# because zsh-autosuggestions doesn't know to clear it; as a workaround, we define
# custom wrapper functions which refreshes the suggestion after expansion

_abbr_expand_and_space_wrapper() {
  zle abbr-expand-and-insert
  zle autosuggest-fetch
}

zle -N _abbr_expand_and_space_wrapper

# rebind space to use the wrapper functions
bindkey " " _abbr_expand_and_space_wrapper
