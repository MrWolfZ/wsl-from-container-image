_rg_fzf() {
  # _rg_fzf - fuzzy-find with rg + fzf (content search only)
  # Usage:
  #   _rg_fzf [-a] [-c <command_name>] [pattern] [directory]
  # Options:
  #   -a  include hidden files
  #   -c  the name of the calling command to show in messages
  # Arguments:
  #   pattern     optional search pattern (if empty, shows all files)
  #   directory   optional directory to search in (defaults to current directory)

  setopt local_options pipefail

  local include_hidden=false command_name="_rg_fzf"
  local OPTIND opt

  while getopts "ac:" opt; do
    case "$opt" in
    a) include_hidden=true ;;
    c) command_name=$OPTARG ;;
    *) ;;
    esac
  done
  shift $((OPTIND - 1))

  # helper for red error
  _err() { printf '\e[31m%s\e[0m\n' "$*" >&2; }

  local pattern="$1"
  local search_dir="${2:-.}"

  local -a hidden_opt=()
  if $include_hidden; then
    hidden_opt=(--hidden --no-ignore)
  fi

  # If pattern is empty, skip initial match check and go straight to fzf
  if [ -z "$pattern" ]; then
    # No pattern: run rg for all files and let fzf handle filtering
    local selected_line
    selected_line="$(rg --follow --line-number --column --no-heading ${hidden_opt[@]} --color=always --smart-case '' "$search_dir" 2>/dev/null |
      awk -F: -v maxw=60 '{
          # reassemble match (fields 4..NF)
          m = ""; for(i=4;i<=NF;i++) m = m (i==4 ? "" : ":") $i;

          f = $1
          # middle truncate if longer than maxw
          if (length(f) > maxw) {
            pre = int(maxw/2) - 1
            suf = maxw - pre - 3   # 3 dots "..."
            f = substr(f, 1, pre) "..." substr(f, length(f)-suf+1)
          }

          # Calculate padding accounting for ANSI color codes
          line_colored = $2
          col_colored = $3

          # Strip ANSI to get visible length
          line_plain = line_colored
          col_plain = col_colored
          gsub(/\033\[[0-9;]*m/, "", line_plain)
          gsub(/\033\[[0-9;]*m/, "", col_plain)

          # Total width = desired visible width + ANSI overhead
          line_width = 6 + (length(line_colored) - length(line_plain))
          col_width = 4 + (length(col_colored) - length(col_plain))

          # Output: metadata\tcontent\toriginal_line
          # Metadata is displayed but not searched; content is both displayed and searched
          printf "%-*s %*s %*s\t%s\t%s\n", maxw, f, line_width, line_colored, col_width, col_colored, m, $0
        }' |
      fzf --delimiter=$'\t' --with-nth=1,2 --nth=2 \
        --preview='line=$(echo {3} | cut -d: -f2); file=$(echo {3} | cut -d: -f1); bat --style=numbers --color=always --paging=never --highlight-line "$line" --line-range $((line > 10 ? line - 10 : 1)):$((line + 10)) "$file" 2>/dev/null || echo "Preview unavailable"' \
        --preview-window='down:60%:wrap')"

    local ret=$?

    # extract the original rg line (field 3)
    selected_line="${selected_line##*$'\t'}"

    # if user cancelled fzf
    if [ "$ret" -ne 0 ]; then
      REPLY=
      return $ret
    fi

    # Convert relative path to absolute
    local file_path="${selected_line%%:*}"
    local rest_of_line="${selected_line#*:}"
    if [[ "$file_path" != /* ]]; then
      file_path="$search_dir/$file_path"
    fi
    file_path="$(realpath "$file_path")"
    selected_line="$file_path:$rest_of_line"

    REPLY="$selected_line"
    return 0
  fi

  # Content search: search inside files and open at match
  # Quick check to see if there are any results
  if ! rg --follow --line-number --column --no-heading ${hidden_opt[@]} --color=never --smart-case --max-count=1 "$pattern" "$search_dir" &>/dev/null; then
    _err "$command_name: no matches found for pattern."
    return 3
  fi

  # Run rg again with color and format for fzf
  local selected_line

  # simple list without formatting if you prefer
  # selected_line="$(rg --line-number --column --no-heading ${hidden_opt[@]} --smart-case "$pattern" "$search_dir" \
  #   | fzf --height=40% --reverse --delimiter ':')"

  # fancy formatting with columns
  selected_line="$(rg --follow --line-number --column --no-heading ${hidden_opt[@]} --color=always --smart-case "$pattern" "$search_dir" 2>/dev/null |
    awk -F: -v maxw=60 '{
          # reassemble match (fields 4..NF)
          m = ""; for(i=4;i<=NF;i++) m = m (i==4 ? "" : ":") $i;

          f = $1
          # middle truncate if longer than maxw
          if (length(f) > maxw) {
            pre = int(maxw/2) - 1
            suf = maxw - pre - 3   # 3 dots "..."
            f = substr(f, 1, pre) "..." substr(f, length(f)-suf+1)
          }

          # Calculate padding accounting for ANSI color codes
          line_colored = $2
          col_colored = $3

          # Strip ANSI to get visible length
          line_plain = line_colored
          col_plain = col_colored
          gsub(/\033\[[0-9;]*m/, "", line_plain)
          gsub(/\033\[[0-9;]*m/, "", col_plain)

          # Total width = desired visible width + ANSI overhead
          line_width = 6 + (length(line_colored) - length(line_plain))
          col_width = 4 + (length(col_colored) - length(col_plain))

          # Output: metadata\tcontent\toriginal_line
          # Metadata is displayed but not searched; content is both displayed and searched
          printf "%-*s %*s %*s\t%s\t%s\n", maxw, f, line_width, line_colored, col_width, col_colored, m, $0
        }' |
    fzf --delimiter=$'\t' --with-nth=1,2 --nth=2 --query="$pattern" \
      --preview='line=$(echo {3} | cut -d: -f2); file=$(echo {3} | cut -d: -f1); bat --style=numbers --color=always --paging=never --highlight-line "$line" --line-range $((line > 10 ? line - 10 : 1)):$((line + 10)) "$file" 2>/dev/null || echo "Preview unavailable"' \
      --preview-window='down:60%:wrap')"

  local ret=$?

  # extract the original rg line (field 3)
  selected_line="${selected_line##*$'\t'}"

  # if user cancelled fzf
  if [ "$ret" -ne 0 ]; then
    REPLY=
    return $ret
  fi

  # Convert relative path to absolute
  local file_path="${selected_line%%:*}"
  local rest_of_line="${selected_line#*:}"
  if [[ "$file_path" != /* ]]; then
    file_path="$search_dir/$file_path"
  fi
  file_path="$(realpath "$file_path")"
  selected_line="$file_path:$rest_of_line"

  REPLY="$selected_line"
  return $?
}
