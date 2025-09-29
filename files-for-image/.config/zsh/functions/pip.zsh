# Sandbox pip install commands inside a podman container to prevent malicious install
# scripts from screwing with the system or exfiltrating credentials
pip() {
  # Path to the real pip binary (avoid recursion)
  local _real_pip
  _real_pip="$(command -v pip)" || _real_pip="/usr/bin/pip3" || _real_pip="/usr/bin/pip"

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
    install|download|wheel)
      # If user asked for global install, ask for confirmation
      for a in "$@"; do
        if [[ $a == "--user" ]]; then
          printf '%s ' "You requested a user install. Continue on host? [y/N]: "
          read -r reply
          if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            printf '%s\n' "Aborted user install."
            return 1
          fi

          # run user install directly on host pip
          command "$_real_pip" "$@"
          return $?
        fi
      done

      # If podman is not available, ask before falling back
      if ! command -v podman >/dev/null 2>&1; then
        printf '%s ' "Podman not found. Run pip directly on host instead? [y/N]: "
        read -r reply
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
          printf '%s\n' "Aborted pip install."
          return 1
        fi

        command "$_real_pip" "$@"
        return $?
      fi

      # Determine a python image to use:
      # Prefer to match the host python version (if python is installed); otherwise fall back to fixed version
      local PYTHON_FALLBACK_VERSION="3.12-alpine"
      local PYTHON_VER PYTHON_MINOR IMAGE
      if command -v python3 >/dev/null 2>&1; then
        PYTHON_VER="$(python3 --version 2>/dev/null | awk '{print $2}' || true)"
        # get major.minor version
        PYTHON_MINOR="${PYTHON_VER%.*}"
        if [[ -n $PYTHON_MINOR ]]; then
          IMAGE="docker.io/library/python:${PYTHON_MINOR}-alpine"
        else
          IMAGE="docker.io/library/python:$PYTHON_FALLBACK_VERSION"
        fi
      else
        IMAGE="docker.io/library/python:$PYTHON_FALLBACK_VERSION"
      fi

      # Sandboxing only makes sens with virtual environments, so we create one if it does not exist
      if [[ ! -d ".venv" ]]; then
        python3 -m venv .venv
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

      PODMAN_ARGS+=(--env "HOME=/tmp")  # avoid writing to host $HOME
      PODMAN_ARGS+=(--security-opt no-new-privileges)
      PODMAN_ARGS+=(--cap-drop ALL)

      # set a few sensible environment variables
      PODMAN_ARGS+=(--env "PIP_DISABLE_PIP_VERSION_CHECK=1")
      PODMAN_ARGS+=(--env "VIRTUAL_ENV=${PWD}/.venv")
      PODMAN_ARGS+=(--env "PATH=${PWD}/.venv/bin:/usr/local/bin:/usr/bin:/bin")

      # make sure image exists (pull if missing)
      if ! podman image exists "$IMAGE"; then
        printf '%s\n' "Pulling container image $IMAGE ... (only the first time)"
        podman pull "$IMAGE" >/dev/null || {
          printf '%s\n' "Warning: failed to pull $IMAGE — falling back to python:$PYTHON_FALLBACK_VERSION" >&2
          IMAGE="docker.io/library/python:$PYTHON_FALLBACK_VERSION"
          podman pull "$IMAGE" >/dev/null 2>&1 || true
        }
      fi

      # Execute pip inside the container with the same args
      printf '%s\n' "Running sandboxed: podman run ${IMAGE} pip $*"
      podman run "${PODMAN_ARGS[@]}" "$IMAGE" pip "$@"
      return $?
      ;;
    *)
      # Non-install: forward to real pip
      if [[ -x "$_real_pip" && "$(command -v pip)" != "$_real_pip" ]]; then
        # If we found a real binary path different from the function name, call it directly
        command "$_real_pip" "$@"
      else
        # Otherwise use command to avoid recursion
        command pip "$@"
      fi
      ;;
  esac
}
