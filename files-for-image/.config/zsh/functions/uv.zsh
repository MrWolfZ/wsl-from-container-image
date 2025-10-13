# Sandbox uv install-like commands inside a podman container to prevent malicious install
# scripts from screwing with the system or exfiltrating credentials
uv() {
  # Path to the real uv binary (avoid recursion)
  local _real_uv
  _real_uv="$(command -v uv)" || _real_uv="/usr/local/bin/uv"

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
  pip | add | sync | lock | install)
    # If user asked for global install, ask for confirmation
    for a in "$@"; do
      if [[ $a == "--system" || $a == "-s" ]]; then
        printf '%s ' "You requested a system-wide install. Continue on host? [y/N]: "
        read -r reply
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
          printf '%s\n' "Aborted system install."
          return 1
        fi

        # run system install directly on host uv
        command "$_real_uv" "$@"
        return $?
      fi
    done

    # If podman is not available, ask before falling back
    if ! command -v podman >/dev/null 2>&1; then
      printf '%s ' "Podman not found. Run uv directly on host instead? [y/N]: "
      read -r reply
      if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        printf '%s\n' "Aborted uv install."
        return 1
      fi

      command "$_real_uv" "$@"
      return $?
    fi

    # Use the official uv container image
    # Use latest tag for simplicity (uv handles Python version internally)
    local IMAGE="ghcr.io/astral-sh/uv:latest"

    # Sandboxing only makes sens with virtual environments, so we create one if it does not exist
    if [[ ! -d ".venv" ]]; then
      uv venv
    fi

    # Build podman run arguments
    # - run as current uid:gid so files created are owned correctly
    # - mount whole project and .venv (venv is a bind so installs persist)
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

    # keep the user ID the same so that the user in the container is allowed to write files
    PODMAN_ARGS+=(--user "$(id -u):$(id -g)")
    PODMAN_ARGS+=(--userns=keep-id)

    # mount project; :Z applies SELinux labeling when needed (harmless otherwise)
    PODMAN_ARGS+=(-v "${PWD}:${PWD}:Z")

    # Mount any pip.conf / .pypirc files found in the current directory hierarchy
    local _dir _pip_conf_path _pypirc_path
    _dir="$PWD"
    while :; do
      _pip_conf_path="${_dir}/pip.conf"
      _pypirc_path="${_dir}/.pypirc"

      if [[ -f "$_pip_conf_path" ]]; then
        # avoid duplicate mounts by checking existing PODMAN_ARGS entries
        local _already=false
        for _arg in "${PODMAN_ARGS[@]}"; do
          if [[ "$_arg" == "-v" ]]; then
            continue
          fi
          if [[ "$_arg" == *"${_pip_conf_path}:"* || "$_arg" == *":${_pip_conf_path}"* ]]; then
            _already=true
            break
          fi
        done
        if [[ $_already == false ]]; then
          PODMAN_ARGS+=(-v "${_pip_conf_path}:${_pip_conf_path}:ro,Z")
        fi
      fi

      if [[ -f "$_pypirc_path" ]]; then
        # avoid duplicate mounts by checking existing PODMAN_ARGS entries
        local _already=false
        for _arg in "${PODMAN_ARGS[@]}"; do
          if [[ "$_arg" == "-v" ]]; then
            continue
          fi
          if [[ "$_arg" == *"${_pypirc_path}:"* || "$_arg" == *":${_pypirc_path}"* ]]; then
            _already=true
            break
          fi
        done
        if [[ $_already == false ]]; then
          PODMAN_ARGS+=(-v "${_pypirc_path}:${_pypirc_path}:ro,Z")
        fi
      fi

      # stop at filesystem root
      if [[ "$_dir" == "/" || "$_dir" == "." || "$_dir" == "$(dirname "$_dir")" ]]; then
        break
      fi
      _dir="$(dirname "$_dir")"
    done

    # mount .venv separately to ensure install writes to host venv
    PODMAN_ARGS+=(-v "${PWD}/.venv:${PWD}/.venv:Z")
    PODMAN_ARGS+=(-w ${PWD})

    # mount uv directories to make symlinks work correctly
    # (venv symlinks point to ~/.local/share/uv/python/...)
    local UV_CACHE_DIR="${HOME}/.cache/uv"
    local UV_DATA_DIR="${HOME}/.local/share/uv"
    mkdir -p "$UV_CACHE_DIR" "$UV_DATA_DIR"
    PODMAN_ARGS+=(-v "${UV_CACHE_DIR}:${UV_CACHE_DIR}:Z")
    PODMAN_ARGS+=(-v "${UV_DATA_DIR}:${UV_DATA_DIR}:Z")

    # use actual HOME so paths match and symlinks work
    PODMAN_ARGS+=(--env "HOME=${HOME}")
    PODMAN_ARGS+=(--security-opt no-new-privileges)
    PODMAN_ARGS+=(--cap-drop ALL)

    # set a few sensible environment variables
    PODMAN_ARGS+=(--env "VIRTUAL_ENV=${PWD}/.venv")
    PODMAN_ARGS+=(--env "UV_PROJECT_ENVIRONMENT=${PWD}/.venv")

    # make sure image exists (pull if missing)
    if ! podman image exists "$IMAGE"; then
      printf '%s\n' "Pulling container image $IMAGE ... (only the first time)"
      podman pull "$IMAGE" >/dev/null || {
        printf '%s\n' "Error: failed to pull $IMAGE" >&2
        return 1
      }
    fi

    # Execute uv inside the container with the same args
    printf '%s\n' "Running sandboxed: podman run ${IMAGE} $*"
    podman run "${PODMAN_ARGS[@]}" "$IMAGE" "$@"
    return $?
    ;;
  *)
    # Non-install: forward to real uv
    if [[ -x "$_real_uv" && "$(command -v uv)" != "$_real_uv" ]]; then
      # If we found a real binary path different from the function name, call it directly
      command "$_real_uv" "$@"
    else
      # Otherwise use command to avoid recursion
      command uv "$@"
    fi
    ;;
  esac
}
