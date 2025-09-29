# Performant git commit info segments for powerlevel10k
# Shows hash, subject, author, and relative age of the latest commit
# Optimized for performance with caching and minimal git operations

# Configuration: Colors can be customized via environment variables
typeset -g POWERLEVEL9K_GIT_COMMIT_HASH_FOREGROUND="${POWERLEVEL9K_GIT_COMMIT_HASH_FOREGROUND:-51}"      # cyan
typeset -g POWERLEVEL9K_GIT_COMMIT_SUBJECT_FOREGROUND="${POWERLEVEL9K_GIT_COMMIT_SUBJECT_FOREGROUND:-220}" # gold
typeset -g POWERLEVEL9K_GIT_COMMIT_AUTHOR_FOREGROUND="${POWERLEVEL9K_GIT_COMMIT_AUTHOR_FOREGROUND:-244}"   # gray
typeset -g POWERLEVEL9K_GIT_COMMIT_AGE_FOREGROUND="${POWERLEVEL9K_GIT_COMMIT_AGE_FOREGROUND:-213}"         # magenta

# Cache to avoid repeated git calls
typeset -gA _p10k_git_commit_cache
typeset -g _p10k_git_commit_cache_key=

# Get commit info efficiently with a single git call
# Returns: hash|subject|author|age
_git_commit_info() {
  # Check if we're in a git repo and get repo path + HEAD ref
  local git_dir
  git_dir=$(git rev-parse --git-dir 2>/dev/null) || return 1

  local repo_path="${git_dir:h}"
  local head_file="${git_dir}/HEAD"

  # Create cache key from repo path and HEAD modification time
  local cache_key="${repo_path}:$(zstat +mtime "$head_file" 2>/dev/null || echo 0)"

  # Return cached value if still valid
  if [[ "$cache_key" == "$_p10k_git_commit_cache_key" ]]; then
    echo "$_p10k_git_commit_cache[$cache_key]"
    return 0
  fi

  # Single git call to get all info at once (very fast)
  local info
  info=$(git log -1 --format='%h|%s|%an|%ar' 2>/dev/null) || return 1

  # Update cache
  _p10k_git_commit_cache_key="$cache_key"
  _p10k_git_commit_cache[$cache_key]="$info"

  echo "$info"
}

# Segment: Git commit hash (short)
prompt_git_commit_hash() {
  local info=$(_git_commit_info) || return
  local hash="${info%%|*}"

  [[ -n "$hash" ]] && p10k segment -f "$POWERLEVEL9K_GIT_COMMIT_HASH_FOREGROUND" -i '' -t "$hash"
}

# Segment: Git commit subject (message)
prompt_git_commit_subject() {
  local info=$(_git_commit_info) || return
  local subject="${${info#*|}%%|*}"

  # Truncate long subjects to 50 chars
  if (( ${#subject} > 50 )); then
    subject="${subject[1,47]}..."
  fi

  [[ -n "$subject" ]] && p10k segment -f "$POWERLEVEL9K_GIT_COMMIT_SUBJECT_FOREGROUND" -i '󰊢' -t "$subject"
}

# Segment: Git commit author
prompt_git_commit_author() {
  local info=$(_git_commit_info) || return
  local author="${${info%|*}##*|}"

  [[ -n "$author" ]] && p10k segment -f "$POWERLEVEL9K_GIT_COMMIT_AUTHOR_FOREGROUND" -i '' -t "$author"
}

# Segment: Git commit age (relative time)
prompt_git_commit_age() {
  local info=$(_git_commit_info) || return
  local age="${info##*|}"

  [[ -n "$age" ]] && p10k segment -f "$POWERLEVEL9K_GIT_COMMIT_AGE_FOREGROUND" -i '󱑎' -t "$age"
}

# Instant prompt support (uses empty cache initially)
function instant_prompt_git_commit_hash() {
  prompt_git_commit_hash
}

function instant_prompt_git_commit_subject() {
  prompt_git_commit_subject
}

function instant_prompt_git_commit_author() {
  prompt_git_commit_author
}

function instant_prompt_git_commit_age() {
  prompt_git_commit_age
}
