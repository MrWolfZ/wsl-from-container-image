# Sandbox npm install-like commands inside a podman container to prevent malicious install
# scripts from screwing with the system or exfiltrating credentials
npm() {
  # Path to the real npm binary (avoid recursion)
  local _real_npm
  _real_npm="$(command -v npm)" || _real_npm="/usr/bin/npm"

  # find the first non-option argument (the subcommand)
  local sub_cmd=""
  for arg in "$@"; do
    if [[ $arg == -- ]]; then
      # next arg is the subcommand
      shift
      sub_cmd="$1"
      break
    fi
    if [[ $arg == -* ]]; then
      continue
    fi
    sub_cmd=$arg
    break
  done

  # normalize to lowercase
  if [[ -n $sub_cmd ]]; then
    sub_cmd="${sub_cmd:l}"
  fi

  # list of install-like subcommands to sandbox
  case "$sub_cmd" in
  install | i | ci | add | install-ci-test)
    # If user asked for global install, ask for confirmation
    for a in "$@"; do
      if [[ $a == "-g" || $a == "--global" ]]; then
        printf '%s ' "You requested a global install. Continue on host? [y/N]: "
        read -r reply
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
          printf '%s\n' "Aborted global install."
          return 1
        fi

        # run global install directly on host npm
        command "$_real_npm" "$@"
        return $?
      fi
    done

    # If podman is not available, ask before falling back
    if ! command -v podman >/dev/null 2>&1; then
      printf '%s ' "Podman not found. Run npm directly on host instead? [y/N]: "
      read -r reply
      if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        printf '%s\n' "Aborted npm install."
        return 1
      fi

      command "$_real_npm" "$@"
      return $?
    fi

    # Determine a node image to use:
    # Prefer to match the host node version (if node is installed); otherwise fall back to fixed version
    local NODE_FALLBACK_VERSION="20-alpine"
    local NODE_VER NODE_MAJOR IMAGE
    if command -v node >/dev/null 2>&1; then
      NODE_VER="$(node --version 2>/dev/null || true)"
      # strip leading 'v' if present, get major version
      NODE_VER="${NODE_VER#v}"
      NODE_MAJOR="${NODE_VER%%.*}"
      if [[ -n $NODE_MAJOR ]]; then
        IMAGE="docker.io/library/node:${NODE_MAJOR}-alpine"
      else
        IMAGE="docker.io/library/node:$NODE_FALLBACK_VERSION"
      fi
    else
      IMAGE="docker.io/library/node:$NODE_FALLBACK_VERSION"
    fi

    # Create node_modules dir if it doesn't exist so mount works
    if [[ ! -d "node_modules" ]]; then
      mkdir -p node_modules || {
        printf '%s\n' "Warning: could not create node_modules in $PWD — continuing." >&2
      }
    fi

    # Build podman run arguments
    # - run as current uid:gid so files created are owned correctly
    # - mount whole project and node_modules (node_modules is a bind so installs persist)
    # - set working dir to ${PWD} to mirror paths on the host
    # - drop extra capabilities and set no-new-privileges
    # - --rm to remove container after exit
    # - pass through tty if interactive shell
    local PODMAN_ARGS=()
    PODMAN_ARGS+=(--rm)

    # preserve interactive TTY when appropriate
    if [[ -t 1 ]]; then
      PODMAN_ARGS+=(-it)
    fi

    # keep the user ID the same to that the user in the container is allowed to write files
    PODMAN_ARGS+=(--user "$(id -u):$(id -g)")
    PODMAN_ARGS+=(--userns=keep-id)

    # mount project; :Z applies SELinux labeling when needed (harmless otherwise)
    PODMAN_ARGS+=(-v "${PWD}:${PWD}:Z")

    # Mount any .npmrc files found in the current directory hierarchy
    local _dir _npmrc_path
    _dir="$PWD"
    while :; do
      _npmrc_path="${_dir}/.npmrc"
      if [[ -f "$_npmrc_path" ]]; then
        # avoid duplicate mounts by checking existing PODMAN_ARGS entries
        local _already=false
        for _arg in "${PODMAN_ARGS[@]}"; do
          if [[ "$_arg" == "-v" ]]; then
            continue
          fi
          if [[ "$_arg" == *"${_npmrc_path}:"* || "$_arg" == *":${_npmrc_path}"* ]]; then
            _already=true
            break
          fi
        done
        if [[ $_already == false ]]; then
          PODMAN_ARGS+=(-v "${_npmrc_path}:${_npmrc_path}:ro,Z")
        fi
      fi

      # stop at filesystem root
      if [[ "$_dir" == "/" || "$_dir" == "." || "$_dir" == "$(dirname "$_dir")" ]]; then
        break
      fi
      _dir="$(dirname "$_dir")"
    done

    # mount node_modules separately to ensure install writes to host node_modules
    PODMAN_ARGS+=(-v "${PWD}/node_modules:${PWD}/node_modules:Z")
    PODMAN_ARGS+=(-w ${PWD})

    PODMAN_ARGS+=(--env "HOME=/tmp") # avoid writing to host $HOME
    PODMAN_ARGS+=(--security-opt no-new-privileges)
    PODMAN_ARGS+=(--cap-drop ALL)

    # set a few sensible environment variables
    PODMAN_ARGS+=(--env "npm_config_fund=false")
    PODMAN_ARGS+=(--env "npm_config_update-notifier=false")

    # make sure image exists (pull if missing)
    if ! podman image exists "$IMAGE"; then
      printf '%s\n' "Pulling container image %s ... (only the first time)" "$IMAGE"
      podman pull "$IMAGE" >/dev/null || {
        printf '%s\n' "Warning: failed to pull %s — falling back to node:$NODE_FALLBACK_VERSION" "$IMAGE" >&2
        IMAGE="docker.io/library/node:$NODE_FALLBACK_VERSION"
        podman pull "$IMAGE" >/dev/null 2>&1 || true
      }
    fi

    # Execute npm inside the container with the same args
    # Use --preserve-fds? not necessary. Forward env vars if needed.
    printf '%s\n' "Running sandboxed: podman run ${IMAGE} npm $*"
    podman run "${PODMAN_ARGS[@]}" "$IMAGE" npm "$@"
    return $?
    ;;
  *)
    # Non-install: forward to real npm
    if [[ -x "$_real_npm" && "$(command -v npm)" != "$_real_npm" ]]; then
      # If we found a real binary path different from the function name, call it directly
      command "$_real_npm" "$@"
    else
      # Otherwise use command to avoid recursion
      command npm "$@"
    fi
    ;;
  esac
}
