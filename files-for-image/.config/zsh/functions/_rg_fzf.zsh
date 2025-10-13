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

	local hidden_opt=""
	if $include_hidden; then
		hidden_opt="--hidden"
	fi

	# If pattern is empty, skip initial match check and go straight to fzf
	if [ -z "$pattern" ]; then
		# No pattern: run rg for all files and let fzf handle filtering
		local selected_line
		selected_line="$(rg --line-number --column --no-heading $hidden_opt --color=always --smart-case '' "$search_dir" 2>/dev/null |
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
			fzf --reverse --delimiter=$'\t' --with-nth=1,2 --nth=2 --ansi)"

		local ret=$?

		# extract the original rg line (field 3)
		selected_line="${selected_line##*$'\t'}"

		# if user cancelled fzf
		if [ "$ret" -ne 0 ]; then
			REPLY=
			return $ret
		fi

		REPLY="$selected_line"
		return 0
	fi

	# Content search: search inside files and open at match
	# Run rg and capture raw results (limit to 2 for performance)
	local raw_results
	raw_results="$(rg --line-number --column --no-heading $hidden_opt --color=never --smart-case --max-count=2 "$pattern" "$search_dir" 2>/dev/null | head -n 2)"

	if [ -z "$raw_results" ]; then
		_err "$command_name: no matches found for pattern."
		return 3
	fi

	# Count number of results (max 2)
	local count
	count="$(printf '%s\n' "$raw_results" | wc -l)"

	# If only one result, return it directly
	if [ "$count" -eq 1 ]; then
		REPLY="$raw_results"
		return 0
	fi

	# Multiple results: run rg again with color and format for fzf
	local selected_line

	# simple list without formatting if you prefer
	# selected_line="$(rg --line-number --column --no-heading $hidden_opt --smart-case "$pattern" "$search_dir" \
	#   | fzf --height=40% --reverse --delimiter ':')"

	# fancy formatting with columns
	selected_line="$(rg --line-number --column --no-heading $hidden_opt --color=always --smart-case "$pattern" "$search_dir" 2>/dev/null |
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
		fzf --reverse --delimiter=$'\t' --with-nth=1,2 --nth=2 --ansi --query="$pattern")"

	local ret=$?

	# extract the original rg line (field 3)
	selected_line="${selected_line##*$'\t'}"

	# if user cancelled fzf
	if [ "$ret" -ne 0 ]; then
		REPLY=
		return $ret
	fi

	REPLY="$selected_line"
	return $?
}
