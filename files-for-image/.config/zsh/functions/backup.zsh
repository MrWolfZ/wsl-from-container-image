#!/usr/bin/env zsh

# Backup home directory to compressed tarball
# Excludes binaries, caches, build outputs, and temporary files
backup() {
	local timestamp=$(date +%Y%m%d-%H%M%S)
	local hostname=$(hostname)
	local tmp_tar="/tmp/backup-${hostname}-${timestamp}.tar.xz"
	local final_tar="${HOME}/backup-${hostname}-${timestamp}.tar.xz"

	echo "Creating backup of home directory..."
	echo "Temporary file: ${tmp_tar}"
	echo "Final location: ${final_tar}"
	echo ""

	# Create exclusion list
	local -a excludes=(
		# Caches and temporary files
		--exclude='.cache'
		--exclude='**/.cache'
		--exclude='**/__pycache__'
		--exclude='**/node_modules'
		--exclude='**/.pytest_cache'
		--exclude='**/.mypy_cache'
		--exclude='**/.ruff_cache'
		--exclude='**/.tox'

		# Build outputs
		--exclude='**/target' # Rust
		--exclude='**/dist'
		--exclude='**/build'
		--exclude='**/*.o'
		--exclude='**/*.a'
		--exclude='**/*.so'
		--exclude='**/*.so.*'
		--exclude='**/*.dll'
		--exclude='**/*.exe'
		--exclude='**/*.dylib'
		--exclude='**/bin/Debug'
		--exclude='**/bin/Release'
		--exclude='**/obj'

		# Language-specific
		--exclude='**/.venv'
		--exclude='**/venv'
		--exclude='**/*.pyc'
		--exclude='**/*.pyo'
		--exclude='**/.tsbuildinfo'
		--exclude='**/*.class'

		# IDE and editor
		--exclude='**/.idea'
		--exclude='**/*.swp'
		--exclude='**/*.swo'
		--exclude='**/*~'

		# OS files
		--exclude='**/.DS_Store'
		--exclude='**/Thumbs.db'

		# VSCode server (large binary files)
		--exclude='.vscode-server'
		--exclude='.vscode-remote-containers'

		# ZSH compiled files
		--exclude='**/*.zwc'
		--exclude='.zcompdump*'

		# Session/runtime files
		--exclude='.dbus'
		--exclude='.sudo_as_admin_successful'

		# Backup files themselves
		--exclude='backup-*.tar.gz'
		--exclude='backup-*.tar.xz'
	)

	# Directories to include
	local -a include_dirs=(
		.config
		.ssh
		.claude
		.kube
		src
		.cargo/config.toml
		.gemini
		.mc
	)

	# Filter to only existing directories/files
	local -a existing_includes=()
	for item in $include_dirs; do
		if [[ -e "$HOME/$item" ]]; then
			existing_includes+=("$item")
		fi
	done

	if [[ ${#existing_includes[@]} -eq 0 ]]; then
		echo "Error: No directories to backup found"
		return 1
	fi

	echo "Backing up directories:"
	printf '  %s\n' $existing_includes
	echo ""

	# Create tarball with xz compression
	cd "$HOME" || return 1
	echo "Computing uncompressed backup size..."
	total_bytes="$(du -sbc $excludes $existing_includes | tail -1 | awk '{print $1}')"
	echo "Total uncompressed backup size is $(echo $total_bytes | numfmt --to=iec-i)"
	echo ""

	echo "Creating backup archive..."
	tar cf - $excludes $existing_includes -P | pv -s $total_bytes | xz -1 -T0 >"$tmp_tar"

	if [[ $? -eq 0 ]]; then
		mv "$tmp_tar" "$final_tar"
		local size=$(du -h "$final_tar" | cut -f1)
		echo ""
		echo "✓ Backup complete: ${final_tar} (${size})"
	else
		echo ""
		echo "✗ Backup failed"
		rm -f "$tmp_tar"
		return 1
	fi
}
