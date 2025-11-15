# WSL Distro Builder - Agent Guide

## Project Overview

This project builds custom WSL (Windows Subsystem for Linux) distributions from container images using Podman/Docker. The build system creates layered container images that are exported as tar files and imported into WSL on Windows. The project supports three main variants: **min** (minimal), **dev** (developer tools), and **ai** (AI/GPU support).

## Architecture

### Build System Flow

1. **Base Layer** (`base.Containerfile`) - Ubuntu 24.04 foundation with system packages, dev user, and essential tools (single-stage build)
2. **Variant Base Layer** (`{variant}-base.Containerfile`) - Variant-specific development tools and runtimes
3. **Shell Layer** (`shell-tools.Containerfile`) - Shell configuration, modern CLI tools (eza, bat, fzf, fd, ripgrep, zoxide, btop, delta, direnv, lazygit, nano, neovim, micro, superfile, yazi, shfmt), and powerlevel10k theme
4. **Export & Import** - Container exported as tar, then imported into WSL via Windows CMD scripts

### Multi-Stage Build Strategy

The Containerfiles use multi-stage builds extensively to:

- Compile tools from source in isolated stages (e.g., podman, rust tools, go tools)
- Copy only binaries/artifacts to final image (reduces image size)
- Leverage caching via SHA256 checksums to skip unchanged layers

**Shell Layer Optimization:**

The `shell-tools.Containerfile` uses a two-tier build argument strategy for optimal layer caching:

- **`BASE_IMAGE`** - Used by the `base-with-dev-user` stage and all tool download/compilation stages
- **`VARIANT_BASE_IMAGE`** - Used only by the final assembly stage

The `base-with-dev-user` stage (which sets `USER dev`, `SHELL ["/bin/bash", "-c"]`, and `WORKDIR /home/dev`) serves as the base for all tool download stages (`base-gitstatus`, `base-direnv`, `base-ripgrep`, `base-fzf`, `base-fd`, `base-zoxide`, `base-eza`, `base-bat`, `base-btop`, `base-delta`, `base-lazygit`, `base-nano`, `base-neovim`, `base-micro`, `base-superfile`, `base-yazi`, `base-shfmt`). This intermediate stage ensures that:

1. All tool stages run as the `dev` user (not root)
2. Shell tool downloads are cached independently of variant-specific changes
3. The base image remains suitable for variant-base images that need root access

If you modify a variant-base Containerfile (e.g., `dev-base.Containerfile`), the shell tools won't need to be re-downloaded since they're built from the unchanged base image.

### Key Files

- **`justfile`** - Build automation (using `just` command runner)
- **Containerfiles**: `base.Containerfile`, `{min,dev,ai}-base.Containerfile`, `shell-tools.Containerfile`
- **`files-for-image/`** - Files copied into the container during build (config files, shell setup)
- **`files-for-tar/`** - Files packaged with the exported tar (import/unregister scripts, fonts)

## Build Variants

### 1. Min Variant (`min-base.Containerfile`)

- Minimal installation on top of base
- Just adds wsl.conf configuration
- For lightweight usage

### 2. Dev Variant (`dev-base.Containerfile`)

**Development tools installed:**

- **Languages**: Go, Rust, Python (via uv), Node.js (via fnm), Java (17 & 21), .NET (8.0 & 9.0)
- **Container runtime**: Rootless Podman with all dependencies (slirp4netns, conmon, netavark, aardvark-dns, crun, CNI plugins)
- **Container tools**: dive (image analysis), lazydocker (container TUI), podman-compose
- **Kubernetes**: kubectl, kubectx/kubens, kubetail, k9s (terminal UI), helm, kubelogin (Azure), clusterctl (Cluster API)
- **Kubernetes cluster tools**: kind (Kubernetes in Docker), k3s (lightweight Kubernetes), kubebuilder
- **Kubernetes networking**: cilium CLI, hubble
- **Security/Secrets**: vault (HashiCorp), kubeseal (sealed-secrets)
- **Object storage**: mc (MinIO client)
- **Other tools**: just (command runner)

**Notable features:**

- All tools compiled from source for latest versions (where applicable)
- Podman configured for rootless operation with systemd support
- Cross-compilation support for ARM64 (for Rust/Go projects)
- Comprehensive Kubernetes toolchain for development and operations
- fnm (Fast Node Manager) is conditionally initialized only if the binary exists

### 3. AI Variant (`ai-base.Containerfile`)

- Builds on dev variant (imports container tools from dev-base)
- Adds NVIDIA Container Toolkit for GPU support
- Includes `ai-init.sh` script to configure CDI for GPU access
- Enables running AI workloads with GPU passthrough in containers

## Configuration Files

### WSL Configuration (`files-for-image/wsl.conf`)

- Systemd enabled for service management
- Custom cgroup v2 mount setup for Podman
- Network configuration with custom hostname
- Windows interop enabled but PATH not appended

### Container Registry Configuration (`files-for-image/registries.conf`)

**Security:**

- **Short-name enforcement**: `short-name-mode = "enforcing"` prevents image spoofing by requiring fully qualified image names
- **Unqualified search**: Falls back to docker.io for unqualified names
- **Local registry**: localhost:5000 allowed with insecure flag for development

### Container Image Policy (`files-for-image/policy.json`)

**Security model:**

- **Default policy**: Reject all unknown registries
- **Allowed registries**: docker.io, ghcr.io, quay.io, registry.k8s.io, gcr.io, registry.access.redhat.com, localhost:5000
- **Local images**: docker-daemon transport accepts all (for locally built images)

This configuration prevents pulling images from unexpected/malicious registries while allowing common public registries used in development.

### Shell Configuration (ZSH)

- **Plugin manager**: Antidote (loads from `.zsh_plugins.txt`)
- **Theme**: Powerlevel10k with instant prompt
- **Plugins**: zsh-autosuggestions, zsh-abbr, fzf-tab, fast-syntax-highlighting, zoxide
- **Features**:
  - Extensive history (1B+ entries)
  - FZF integration for fuzzy finding
  - **fzf-tab**: Fuzzy tab completion using fzf (replaces default zsh completion menu)
  - Custom ripgrep+fzf search functions (see Ripgrep+FZF Search Functions below)
  - Custom navigation function (`di`)
  - Optimized completions (zshzoo style via ez-compinit)
  - **Sandboxed package managers**: npm, uv, pip (see Security Considerations below)
  - **Eza themes**: Community themes from [eza-themes](https://github.com/eza-community/eza-themes) automatically installed; default theme symlinked if none configured
  - **Custom p10k segments**: Git commit info segments (see below)

**fzf-tab Configuration:**

The shell uses fzf-tab to replace zsh's default completion menu with fzf for interactive fuzzy searching through completions. Configuration details:

- **Plugin loading**: fzf-tab must be loaded after compinit (via ez-compinit) but before other completion plugins
- **Menu override**: `zstyle ':completion:*' menu no` overrides zshzoo's default `menu select` to enable fzf-tab
- **Format strings**: Completion format contexts shown within fzf (descriptions, corrections, messages) are overridden with clean bracket format since fzf-tab cannot render color escape sequences. The warnings format keeps colors (red) since it's displayed outside fzf.
- **File colorization**: LS_COLORS is saved before being unset for eza, then restored for completion to enable colored file listings in fzf-tab
- **Git checkout**: Sorting disabled to preserve chronological branch order (most recent branches appear first)
- **cd preview**: Shows detailed eza listing when completing cd commands (all files, icons, git status)
- **UI layout**: Full-height interface with reverse layout (input at top) and border for visual clarity
- **Case-insensitive search**: Search is case-insensitive by default via the `-i` flag
- **Group switching**: Use `<` and `>` keys to switch between completion groups (e.g., files vs directories, external vs builtin commands)
- **Compatibility**: Works alongside zshzoo compstyle; overrides `menu` setting and all format-related zstyles

See `.zshrc` lines 80-102 (fzf-tab configuration) and lines 107-131 (LS_COLORS handling) for implementation details.

**FZF Default Options:**

Common fzf options are centralized via `FZF_DEFAULT_OPTS` in `.zshrc` for consistent behavior across all fzf invocations

**FZF History Search (Ctrl+R):**

The fzf history search is configured via `FZF_CTRL_R_OPTS` in `.zshrc` for an optimal search experience

### Search Functions

The shell includes a set of powerful search functions that combine modern CLI tools (ripgrep, fd) with fzf for fast file finding:

**Content Search (search inside files using ripgrep):**

- `r [pattern] [directory]` - Search file contents and return file path
- `ra [pattern] [directory]` - Same as `r` but includes hidden files and ignores .gitignore (uses `--hidden --no-ignore`)
- `rd [pattern] [directory]` - Search file contents and navigate to containing directory
- `rda [pattern] [directory]` - Same as `rd` but includes hidden files and ignores .gitignore (uses `--hidden --no-ignore`)
- `rc [pattern] [directory]` - Search file contents and open in VS Code (or $EDITOR) at exact line/column. Supports multi-selection (Tab/Shift+Tab).
- `rca [pattern] [directory]` - Same as `rc` but includes hidden files and ignores .gitignore (uses `--hidden --no-ignore`). Supports multi-selection (Tab/Shift+Tab).

**Filename Search (search filenames using fd):**

- `n [pattern] [directory]` - Search filenames and return file path (also sets `$selected_path` variable)
- `na [pattern] [directory]` - Same as `n` but includes hidden files (also sets `$selected_path` variable)
- `nd [pattern] [directory]` - Search filenames and navigate to directory (or parent if file)
- `nda [pattern] [directory]` - Same as `nd` but includes hidden files
- `nc [pattern] [directory]` - Search filenames and open in VS Code (or $EDITOR)
- `nca [pattern] [directory]` - Same as `nc` but includes hidden files

**Features:**

- Pattern parameter is optional; if omitted, shows all content/files for interactive fzf filtering
- When a pattern is provided for filename search, it's passed to fzf via `--query` (not to fd); fd always lists all files and fzf handles filtering
- When a pattern is provided for content search, it's used as the initial fzf query via `--query`
- All functions accept an optional directory parameter (defaults to current directory)
- `n` and `na` functions set the `$selected_path` global variable with the selected path for use in subsequent commands
- Content search uses ripgrep's regex syntax and follows symlinks; filename search uses fzf's fuzzy matching
- `*c` functions intelligently detect VS Code Server availability and fall back to `$EDITOR` if not present
- `nc` and `nca` functions reuse the current VS Code window only for files; directories open in a new window
- Functions with `a` suffix search hidden files/directories; for content search, also ignores .gitignore (passes `--hidden --no-ignore` to ripgrep)
- **Content search preview**: Shows 10 lines of context (±10 lines) around matched line using bat with syntax highlighting, line numbers, and highlight on the matched line. Preview appears at the bottom of the fzf window (fixed height of 23 lines).
- **Filename search preview**: Intelligently uses eza for directories and bat for files
- **History integration**: All `*c`, `*d`, and `*da` functions add their commands to zsh history, allowing easy repetition via up-arrow or history search. Commands are properly quoted when paths contain spaces or special characters.
- **Path resolution**: Content search functions (`r*`) return absolute paths resolved from the search directory, ensuring editor commands work correctly regardless of current directory.
- **Multi-selection**: `rc` and `rca` support selecting multiple files in fzf using Tab (select) and Shift+Tab (deselect). All selected files are opened in the editor, with VS Code receiving goto positions for each file.

### Process Management Functions

The shell includes interactive process management functions that use fzf for selecting processes to send signals to:

**Process Kill Functions:**

- `killf <signal> [query]` - Interactively select user processes and send signal
- `killfa <signal> [query]` - Interactively select from all processes (system-wide) and send signal

**Arguments:**

- `signal` (required) - Signal to send (e.g., `-9`, `-15`, `-TERM`, `-KILL`)
- `query` (optional) - String passed to fzf as `--query` to prefilter the process list

**Features:**

- **Multi-selection**: Use Tab to select multiple processes, Shift+Tab to deselect. All selected processes receive the signal.
- **Process filtering**: `killf` shows only processes owned by the current user; `killfa` shows all processes system-wide
- **Process preview**: Shows detailed process information (PID, PPID, user, start time, CPU time, memory, command) in the preview window
- **Interactive search**: Filter processes in real-time using fzf's fuzzy matching
- **Formatted display**: Processes displayed with aligned columns showing PID, user, %CPU, %MEM, and command
- **Safe operation**: Requires explicit signal parameter and interactive selection before sending signals

**Usage examples:**

```bash
# Kill a user process with SIGTERM (graceful shutdown)
killf -15

# Kill a user process with SIGKILL (force kill)
killf -9

# Search for "python" processes and kill with SIGTERM
killf -15 python

# Kill any system process (requires appropriate permissions)
killfa -9 nginx

# Kill multiple processes at once (select with Tab)
killf -15  # Then use Tab to select multiple processes
```

### Powerlevel10k Git Commit Segments

Custom p10k segments that display information about the latest git commit. These segments are highly optimized with intelligent caching to avoid repeated git calls.

**Available segments:**

- `git_commit_hash` - Short commit hash (7 characters)
- `git_commit_subject` - Commit message (auto-truncated to 50 chars)
- `git_commit_author` - Commit author name
- `git_commit_age` - Relative commit age (e.g., "2 hours ago", "3 days ago")

**Performance features:**

- **Single git call**: All four segments share one `git log` invocation
- **Smart caching**: Results cached based on repository path + HEAD modification time
- **Instant prompt compatible**: Supports p10k's instant prompt feature
- **Zero overhead when not in git repo**: Quick exit if no git repository detected

**Configuration:**

To use these segments, add one or more to `POWERLEVEL9K_LEFT_PROMPT_ELEMENTS` or `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` in `.p10k.zsh`:

```zsh
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  # ... other segments ...
  git_commit_hash
  git_commit_subject
  git_commit_author
  git_commit_age
)
```

**Color customization:**

Override default colors by setting these variables in `.p10k.zsh` (before sourcing the file):

```zsh
typeset -g POWERLEVEL9K_GIT_COMMIT_HASH_FOREGROUND=51      # cyan (default)
typeset -g POWERLEVEL9K_GIT_COMMIT_SUBJECT_FOREGROUND=220  # gold (default)
typeset -g POWERLEVEL9K_GIT_COMMIT_AUTHOR_FOREGROUND=244   # gray (default)
typeset -g POWERLEVEL9K_GIT_COMMIT_AGE_FOREGROUND=213      # magenta (default)
```

**Implementation:**

- Segment definitions: `p10k_segments/git_commit.zsh`
- Loaded in: `.zshrc` lines 109
- Documentation: `.p10k.zsh` lines 512-528

### Shell Utility Functions

**direnv_list** - List direnv-exported environment variables

Displays environment variables currently exported by direnv in the active directory.

**Usage:**

```bash
direnv_list       # Show variable names only
direnv_list -v    # Show variable names and values
```

**Features:**

- Checks if direnv is active in the current directory
- Uses `direnv export json` for accurate state detection
- Filters out `DIRENV_*` internal variables
- Sorted alphabetical output
- **PATH diff**: When showing values, `PATH` is displayed as a diff against the default user PATH:
  - `PATH+=<entry>` - Entries added by direnv
  - `PATH-=<entry>` - Entries removed by direnv
- Requires jq for JSON parsing

**Implementation:** `functions/direnv_list.zsh`

### Podman Configuration (`files-for-image/containers.conf`)

**Performance optimizations:**

- **Parallel image pulls**: `image_parallel_copies = 0` (unlimited parallel layer fetching)
- **Journald integration**: `events_logger = "journald"` and `log_driver = "journald"` for systemd compatibility
- **Reduced stop timeout**: `stop_timeout = 10` (faster container shutdown)
- **Log size limits**: `log_size_max = 10485760` (10MB cap to prevent disk bloat)

**Security settings:**

- **Minimal capabilities**: Explicit capability whitelist (CHOWN, DAC_OVERRIDE, FOWNER, FSETID, KILL, NET_BIND_SERVICE, SETFCAP, SETGID, SETPCAP, SETUID)
- **User namespaces**: `userns = "auto"` for automatic namespace mapping
- **Init process**: `init = true` for proper signal handling

**Infrastructure:**

- Helper binaries located in `/usr/local/libexec/podman`
- Netavark network backend
- Increased PID limit (16584)

## Build Process (justfile)

### Main Commands

```bash
just build <variant>                         # Build image + tar structure
just build-image <variant> [stage] [layer]   # Build container image only (optionally to specific stage/layer)
just build-tar <variant>                     # Prepare tar package structure
just run <variant>                           # Run container interactively for testing
just export <variant>                        # Export container filesystem to tar
just install <variant>                       # Copy build artifacts to /mnt/c/wsl
```

**Building to Specific Stages:**

The `build-image` command supports optional `stage` and `layer` parameters to build only up to a specific stage in multi-stage builds:

```bash
just build-image dev                      # Full build (default)
just build-image dev base-podman          # Build only to 'base-podman' stage in variant-base layer
just build-image dev base-rust            # Build only to 'base-rust' stage in variant-base layer
just build-image dev "" shell             # Build only the shell layer (skips variant-base rebuild)
just build-image dev base-eza shell       # Build shell layer only to 'base-eza' stage
```

This is useful for quickly verifying newly added stages without doing a full rebuild (which can be very slow). When building to a specific stage:

- The `--target <stage>` flag is passed to podman/docker build
- Checksum updates are skipped (incomplete builds don't update checksums)
- If `layer` is omitted or set to `variant-base`, the shell layer build is skipped when a stage is specified
- If `layer` is set to `shell`, the variant-base layer is skipped entirely and only the shell layer is built
- The base layer always follows normal checksum logic

### Build Optimizations

1. **SHA256 Checksums**: Base images tracked with checksums, only rebuild if Containerfile changes
2. **Conditional Builds**: Script checks if images exist + checksums match before rebuilding
3. **Parallel Stages**: Multi-stage builds allow parallel compilation where possible
4. **Version Pinning**: All tools pinned to specific versions in justfile variables

### Import Process (Windows)

1. Run `{version}-{variant}-{base}-import.cmd` from Windows
2. Script performs:
   - WSL import of tar file
   - DNS configuration (copies Windows DNS servers to /etc/resolv.conf)
   - Sysctl tuning (inotify limits for file watchers)
   - WSL interop fix (binfmt configuration)
   - apt-get update & upgrade
   - Password setup for dev user

## Development Workflow

Whenever you start working on any task, first create a TODO list for yourself to keep track of the work you are doing.

**AFTER YOU MAKE ANY CHANGE TO THIS PROJECT, YOU MUST UPDATE THIS `AGENTS.md` FILE IMMEDIATELY.**

This includes but is not limited to:

- Adding/removing/updating tools or dependencies
- Modifying justfile commands or their behavior
- Changing Containerfile build stages or structure
- Adding/removing configuration files
- Modifying build optimizations or strategies
- Changing shell configuration or plugins
- Any workflow or process changes

**DO NOT SKIP THIS STEP.** Future agents rely on this documentation being accurate and up-to-date. Failing to update this file means future agents will have incorrect information and may make mistakes or waste time.

After making changes, update the relevant section(s) of this document to reflect:

1. What changed
2. How to use the new/modified feature
3. Any new commands, parameters, or workflows
4. Updated version numbers or dependencies

### Adding New Tools

1. Define version variable in `justfile` (e.g., `tool_version := "1.2.3"`)
2. Create build stage in appropriate `{variant}-base.Containerfile`
3. Copy artifacts to final stage with appropriate ownership
4. Add to build args in `justfile` if needed
5. **VALIDATE THE BUILD** (see testing requirements below)
6. Update this AGENTS.md file with the new tool information

### Modifying Shell Config

- Edit files in `files-for-image/.config/zsh/`
- Changes applied during shell-tools.Containerfile layer build
- For testing, edit directly in running container first

### Testing Changes

**ANY change to Containerfiles MUST be validated by building before the work is considered complete.** This is non-negotiable.

Unfortunately, you do not have access to the required tools to do this yourself. Therefore, when you need to test a change (according to the process outlined below), you need to instruct the user to run the command for you. Please make sure to highlight instructions in cyan to make it easier for the user to see them.

Each container image build creates a log file with the build output (with the name format `<containerfile-name>.log`, e.g. `dev-base.Containerfile.log`), which you can inspect to see the result of the operation after the user has reported back.

1. **Test the specific stage first** (fast validation):

   ```bash
   just build-image <variant> <stage-name>
   ```

   Example: `just build-image dev base-lazydocker`

2. **If stage build succeeds, run full build** (full build validation):

   ```bash
   just build-image <variant>
   ```

   Example: `just build-image dev`

3. **If full build succeeds, validate change in built image** (manual validation):

   ```bash
   just run <variant>
   ```

   Example: `just run dev`

4. **Only after successful full build and manual validation, the work is complete**

**If ANY build fails:**

- DO NOT mark the task as complete
- Investigate the error output
- Fix the issue in the Containerfile or justfile
- Re-run the build validation from step 1
- Continue until all builds succeed

**For multi-variant changes** (e.g., adding a tool to both dev and ai):

- Test each affected variant separately
- Both variants must build successfully

**Example workflow for adding a new tool to dev variant:**

```bash
# Step 1: Test just the new stage
just build-image dev base-new-tool

# Step 2: If successful, run full build
just build-image dev

# Step 3: Test the running container (optional but recommended)
just run dev
```

**Pro tip:** When adding a new build stage to a Containerfile, always use the stage-specific build first to catch errors quickly without waiting for a full rebuild.

## Tool Versions (as of justfile)

**Core versions:**

- Go: 1.25.1
- Python: 3.12 (managed via uv 0.8.22)
- fnm (Fast Node Manager): v1.38.1
- Podman: v5.6.1
- Lazydocker: v0.24.1
- Kubectl: v1.34.1
- Ripgrep: 14.1.1
- FZF: 0.65.2
- fd: 10.3.0
- Delta: 0.18.2
- direnv: v2.37.1

**Kubernetes tools:**

- k9s: v0.50.15
- Helm: v3.19.0
- Kubelogin (Azure): v0.2.10
- Clusterctl (Cluster API): v1.11.1
- Cilium CLI: v0.18.7
- Hubble: v1.18.0
- Kind: v0.30.0
- k3s: v1.34.1+k3s1
- Kubebuilder: v4.9.0

**Other tools:**

- Vault: 1.20.4
- Kubeseal: 0.32.2
- MinIO Client (mc): RELEASE.2025-08-13T08-35-41Z

See `justfile` lines 1-135 for complete version manifest.

**Note on k9s:** The "Plugins load failed!" error message displayed on startup is expected behavior when no Kubernetes context is configured. This is harmless and will not appear once k9s is connected to an actual cluster. An empty plugins configuration file is included at `~/.config/k9s/plugins.yaml` for customization.

### k3s Configuration

k3s is included with a systemd user service for rootless operation. The service is created but not enabled by default.

**Service file location:** `~/.config/systemd/user/k3s.service`

**Configuration:**

- Runs in rootless mode (no root privileges required)
- Data directory: `~/.local/share/k3s`
- Kubeconfig: `~/.local/share/k3s/server/cred/admin.kubeconfig`
- Traefik ingress controller enabled by default (for testing ingress resources)
- Disabled components: servicelb (not typically needed in WSL development)
- Kubeconfig is world-readable (mode 644) for convenience

**Helper functions:**

- `k3s_start` - Start the k3s service and wait for it to be ready
- `k3s_stop` - Stop the k3s service

**Usage:**

```bash
# Start k3s
k3s_start

# Export kubeconfig (shown by k3s_start output)
export KUBECONFIG=$HOME/.local/share/k3s/server/cred/admin.kubeconfig

# Use kubectl with k3s
kubectl get nodes

# Stop k3s
k3s_stop
```

**Manual service management:**

```bash
# Enable service to start on boot (optional)
systemctl --user enable k3s

# Start/stop/status
systemctl --user start k3s
systemctl --user stop k3s
systemctl --user status k3s

# View logs
journalctl --user -u k3s -f
```

## Security Considerations

1. **Rootless Podman**: All container operations run as non-root dev user
2. **Protected Binaries**: Tools in `~/.local/bin` owned by root to prevent tampering
3. **Subuid/Subgid Ranges**: Extended to 565536 for rootless containers
4. **Default Password**: "changeme" - MUST be changed on first login
5. **Sandboxed Package Managers**: npm, uv, and pip install commands are automatically sandboxed in Podman containers to prevent malicious install scripts from accessing the host system or exfiltrating credentials

### Sandboxed Package Managers

Three ZSH functions provide automatic sandboxing for package installation commands:

**npm (`files-for-image/.config/zsh/functions/npm.zsh`)**

- Sandboxes: `install`, `i`, `ci`, `add`, `install-ci-test`
- Asks for confirmation before global installs (`-g`, `--global`)
- Mounts project directory, `node_modules`, and `.npmrc` files
- Uses node:X-alpine image matching host node version
- Drops all capabilities, sets `no-new-privileges`, and runs with host UID/GID

**uv (`files-for-image/.config/zsh/functions/uv.zsh`)**

- Sandboxes: `pip`, `add`, `sync`, `lock`, `install`
- Asks for confirmation before system installs (`--system`, `-s`)
- Mounts project directory, `.venv`, `~/.cache/uv`, `~/.local/share/uv` (for Python interpreters), and `pip.conf`/`.pypirc` files
- Sets HOME to actual home directory so venv symlinks work correctly
- Uses official `ghcr.io/astral-sh/uv:latest` container image
- Drops all capabilities, sets `no-new-privileges`, and runs with host UID/GID

**pip (`files-for-image/.config/zsh/functions/pip.zsh`)**

- Sandboxes: `install`, `download`, `wheel`
- Asks for confirmation before user installs (`--user`)
- Mounts project directory, `.venv`, and `pip.conf`/`.pypirc` files
- Uses python:X.Y-alpine image matching host python version
- Drops all capabilities, sets `no-new-privileges`, and runs with host UID/GID

**Security features:**

- All run with `--cap-drop ALL` and `--security-opt no-new-privileges`
- Only specific directories mounted (project, venv, cache, config files) - restricts access to host filesystem
- uv function sets HOME to actual home directory for venv symlink compatibility, but only mounts specific uv directories
- Config files mounted read-only where appropriate
- Falls back to host execution only after explicit user confirmation
- Non-install commands bypass sandboxing for normal operations

## Common Patterns

### Adding a Zsh Plugin

1. Add to `files-for-image/.config/zsh/.zsh_plugins.txt`
2. Antidote will auto-load on next shell startup
3. Use `kind:defer` for non-essential plugins to optimize startup

## File Structure Reference

```txt
.
├── justfile                          # Build automation
├── base.Containerfile                # Ubuntu base + dev user
├── {min,dev,ai}-base.Containerfile   # Variant-specific tools
├── shell-tools.Containerfile         # Shell + CLI tools
├── wsl.Containerfile                 # Legacy/alternative build
├── files-for-image/                  # Copied into container
│   ├── .config/                      # User configs (git, zsh, etc)
│   ├── .zshenv                       # Zsh environment
│   ├── wsl.conf                      # WSL configuration
│   ├── containers.conf               # Podman config
│   ├── registries.conf               # Container registries
│   └── policy.json                   # Image signature policy
├── files-for-tar/                    # Packaged with export
│   ├── import.cmd                    # Windows import script
│   ├── unregister.cmd                # Windows unregister script
│   └── MesloLGS NF *.ttf             # Fonts
├── .build-{variant}/                 # Build output (gitignored)
└── *.sha256                          # Containerfile checksums
```
