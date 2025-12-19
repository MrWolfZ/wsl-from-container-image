version := "25.10"

base_image := "ubuntu:24.04"
base_name := replace(base_image, ":", "-")
base_image_arg := "--build-arg WSL_BASE_IMAGE=wsl-base:" + version + "-" + base_name

container_tool := "podman"
container_build_command := container_tool + " build" + (if container_tool == "podman" { " --format=docker" } else { "" })

# https://github.com/neovim/neovim/tags
neovim_version := "v0.10.3"
neovim_version_arg := " --build-arg NEOVIM_VERSION=" + neovim_version

# https://go.dev/dl/
go_version := "1.25.1"
go_version_arg := " --build-arg GO_VERSION=" + go_version

# https://github.com/astral-sh/uv/tags
uv_version := "0.8.22"
uv_version_arg := " --build-arg UV_VERSION=" + uv_version

python_version := "3.12"
python_version_arg := " --build-arg PYTHON_VERSION=" + python_version

# https://github.com/Schniz/fnm/tags
fnm_version := "v1.38.1"
fnm_version_arg := " --build-arg FNM_VERSION=" + fnm_version

# https://nodejs.org/en/about/previous-releases
node_version := "24"
node_version_arg := " --build-arg NODE_VERSION=" + node_version

# https://github.com/containernetworking/plugins/tags
containernetworking_version := "v1.8.0"
containernetworking_version_arg := " --build-arg CONTAINERNETWORKING_VERSION=" + containernetworking_version

# https://github.com/rootless-containers/slirp4netns/tags
slirp4netns_version := "v1.3.3"
slirp4netns_version_arg := " --build-arg SLIRP4NETNS_VERSION=" + slirp4netns_version

# https://github.com/containers/conmon/tags
conmon_version := "v2.1.13"
conmon_version_arg := " --build-arg CONMON_VERSION=" + conmon_version

# https://github.com/containers/netavark/tags
netavark_version := "v1.16.1"
netavark_version_arg := " --build-arg NETAVARK_VERSION=" + netavark_version

# https://github.com/containers/aardvark-dns/tags
aardvark_dns_version := "v1.16.0"
aardvark_dns_version_arg := " --build-arg AARDVARK_DNS_VERSION=" + aardvark_dns_version

# https://github.com/containers/crun/tags
crun_version := "1.24"
crun_version_arg := " --build-arg CRUN_VERSION=" + crun_version

# https://github.com/containers/podman/tags
podman_version := "v5.6.1"
podman_version_arg := " --build-arg PODMAN_VERSION=" + podman_version

# https://github.com/wagoodman/dive/tags
dive_version := "v0.13.1"
dive_version_arg := " --build-arg DIVE_VERSION=" + dive_version

# https://github.com/jesseduffield/lazydocker/tags
lazydocker_version := "v0.24.1"
lazydocker_version_arg := " --build-arg LAZYDOCKER_VERSION=" + lazydocker_version

# https://github.com/containers/podman-tui/tags
podman_tui_version := "v1.9.0"
podman_tui_version_arg := " --build-arg PODMAN_TUI_VERSION=" + podman_tui_version

# https://github.com/casey/just/tags
just_version := "1.43.0"
just_version_arg := " --build-arg JUST_VERSION=" + just_version

# https://github.com/kubernetes/kubernetes/tags
kubectl_version := "v1.34.1"
kubectl_version_arg := " --build-arg KUBECTL_VERSION=" + kubectl_version

# https://github.com/helm/helm/tags
helm_version := "v3.19.0"
helm_version_arg := " --build-arg HELM_VERSION=" + helm_version

# https://github.com/Azure/kubelogin/tags
kubelogin_version := "v0.2.10"
kubelogin_version_arg := " --build-arg KUBELOGIN_VERSION=" + kubelogin_version

# https://github.com/kubernetes-sigs/cluster-api/tags
clusterctl_version := "v1.11.1"
clusterctl_version_arg := " --build-arg CLUSTERCTL_VERSION=" + clusterctl_version

# https://github.com/cilium/cilium-cli/tags
cilium_version := "v0.18.7"
cilium_version_arg := " --build-arg CILIUM_VERSION=" + cilium_version

# https://github.com/cilium/hubble/tags
hubble_version := "v1.18.0"
hubble_version_arg := " --build-arg HUBBLE_VERSION=" + hubble_version

# https://github.com/kubernetes-sigs/kind/tags
kind_version := "v0.30.0"
kind_version_arg := " --build-arg KIND_VERSION=" + kind_version

# https://github.com/k3s-io/k3s/tags
k3s_version := "v1.34.1+k3s1"
k3s_version_arg := " --build-arg K3S_VERSION=" + k3s_version

# https://github.com/kubernetes-sigs/kubebuilder/tags
kubebuilder_version := "v4.9.0"
kubebuilder_version_arg := " --build-arg KUBEBUILDER_VERSION=" + kubebuilder_version

# https://github.com/kubernetes-sigs/kustomize/tags
kustomize_version := "v5.8.0"
kustomize_version_arg := " --build-arg KUSTOMIZE_VERSION=" + kustomize_version

# https://github.com/hashicorp/vault/tags
vault_version := "1.20.4"
vault_version_arg := " --build-arg VAULT_VERSION=" + vault_version

# https://github.com/bitnami-labs/sealed-secrets/tags
kubeseal_version := "0.32.2"
kubeseal_version_arg := " --build-arg KUBESEAL_VERSION=" + kubeseal_version

# https://github.com/minio/mc/tags
mc_version := "RELEASE.2025-08-13T08-35-41Z"
mc_version_arg := " --build-arg MC_VERSION=" + mc_version

# https://github.com/derailed/k9s/tags
k9s_version := "v0.50.15"
k9s_version_arg := " --build-arg K9S_VERSION=" + k9s_version

# https://github.com/BurntSushi/ripgrep/tags
ripgrep_version := "14.1.1"
ripgrep_version_arg := " --build-arg RIPGREP_VERSION=" + ripgrep_version

# https://github.com/junegunn/fzf/tags
fzf_version := "0.65.2"
fzf_version_arg := " --build-arg FZF_VERSION=" + fzf_version

# https://github.com/sharkdp/fd/tags
fd_version := "10.3.0"
fd_version_arg := " --build-arg FD_VERSION=" + fd_version

# https://github.com/ajeetdsouza/zoxide/tags
zoxide_version := "0.9.8"
zoxide_version_arg := " --build-arg ZOXIDE_VERSION=" + zoxide_version

# https://github.com/eza-community/eza/tags
eza_version := "0.23.4"
eza_version_arg := " --build-arg EZA_VERSION=" + eza_version

# https://github.com/sharkdp/bat/tags
bat_version := "0.25.0"
bat_version_arg := " --build-arg BAT_VERSION=" + bat_version

# https://github.com/aristocratos/btop/tags
btop_version := "1.4.5"
btop_version_arg := " --build-arg BTOP_VERSION=" + btop_version

# https://github.com/dandavison/delta/tags
delta_version := "0.18.2"
delta_version_arg := " --build-arg DELTA_VERSION=" + delta_version

# https://github.com/extrawurst/lazygit/tags
lazygit_version := "0.55.1"
lazygit_version_arg := " --build-arg LAZYGIT_VERSION=" + lazygit_version

# https://github.com/direnv/direnv/tags
direnv_version := "v2.37.1"
direnv_version_arg := " --build-arg DIRENV_VERSION=" + direnv_version

# https://www.nano-editor.org/download.php
nano_version := "8.6"
nano_version_arg := " --build-arg NANO_VERSION=" + nano_version

# https://github.com/zyedidia/micro/tags
micro_version := "2.0.14"
micro_version_arg := " --build-arg MICRO_VERSION=" + micro_version

# https://github.com/yorukot/superfile/tags
superfile_version := "v1.4.0"
superfile_version_arg := " --build-arg SUPERFILE_VERSION=" + superfile_version

# https://github.com/sxyazi/yazi/tags
yazi_version := "v25.5.31"
yazi_version_arg := " --build-arg YAZI_VERSION=" + yazi_version

# https://github.com/mvdan/sh/tags
shfmt_version := "v3.12.0"
shfmt_version_arg := " --build-arg SHFMT_VERSION=" + shfmt_version

# https://github.com/NVIDIA/libnvidia-container/tags
nvidia_container_toolkit_version := "1.17.8-1"
nvidia_container_toolkit_version_arg := " --build-arg NVIDIA_CONTAINER_TOOLKIT_VERSION=" + nvidia_container_toolkit_version

base_build_args := (
  "--build-arg BASE_IMAGE=" + base_image
)

dev_build_args := (
  base_image_arg
  + go_version_arg
  + uv_version_arg
  + python_version_arg
  + fnm_version_arg
  + node_version_arg
  + containernetworking_version_arg
  + slirp4netns_version_arg
  + conmon_version_arg
  + netavark_version_arg
  + aardvark_dns_version_arg
  + crun_version_arg
  + podman_version_arg
  + dive_version_arg
  + lazydocker_version_arg
  + podman_tui_version_arg
  + just_version_arg
  + kubectl_version_arg
  + helm_version_arg
  + kubelogin_version_arg
  + clusterctl_version_arg
  + cilium_version_arg
  + hubble_version_arg
  + kind_version_arg
  + k3s_version_arg
  + kubebuilder_version_arg
  + kustomize_version_arg
  + vault_version_arg
  + kubeseal_version_arg
  + mc_version_arg
  + k9s_version_arg
)

ai_build_args := (
  base_image_arg
  + " --build-arg DEV_BASE_IMAGE=wsl-dev-base:" + version + "-" + base_name
  + nvidia_container_toolkit_version_arg
)

min_build_args := (
  base_image_arg
)

shell_tools_build_args := (
  ripgrep_version_arg
  + fzf_version_arg
  + fd_version_arg
  + zoxide_version_arg
  + eza_version_arg
  + bat_version_arg
  + btop_version_arg
  + delta_version_arg
  + lazygit_version_arg
  + direnv_version_arg
  + nano_version_arg
  + neovim_version_arg
  + micro_version_arg
  + superfile_version_arg
  + yazi_version_arg
  + shfmt_version_arg
)

dev:
  just --list --unsorted

build-image variant="dev" stage="" layer="":
  #!/usr/bin/env bash
  set -euo pipefail

  rm -rf files-for-image-{{ variant }}
  mkdir files-for-image-{{ variant }}
  rsync -ax files-for-image/ files-for-image-{{ variant }}/
  sed -i 's/@@ name @/{{ replace(version + '-' + variant + '-' + base_name, ".", "-") }}/g' files-for-image-{{ variant }}/wsl.conf

  # Determine which layers to build based on layer parameter
  # layer="" (default) -> build all layers
  # layer="variant-base" -> build base + variant-base only (with optional stage)
  # layer="shell-tools" -> build base + variant-base + shell-tools (with optional stage)
  # layer="shell" -> build all layers (no stages, shell.Containerfile has no stages)
  target_layer="{{ if layer != "" { layer } else if stage != "" { "variant-base" } else { "shell" } }}"
  stage_arg="{{ if stage != "" { "--target " + stage } else { "" } }}"

  build_base=true
  build_variant_base=true
  build_shell_tools=true
  build_shell=true

  # Determine which layers to build and which layer gets the stage arg
  if [ "$target_layer" = "variant-base" ]; then
    build_shell_tools=false
    build_shell=false
  elif [ "$target_layer" = "shell-tools" ]; then
    build_shell=false
  fi

  # BASE LAYER
  if [ "$build_base" = true ]; then
    base_image_exists=$({{ container_tool }} image exists wsl-base:{{ version }}-{{ base_name }} && echo -n "yes" || echo -n "no")
    checksum_matches=$(sha256sum --check base.Containerfile.sha256 > /dev/null 2>&1 && echo -n "yes" || echo -n "no")

    if [ "$base_image_exists" != "yes" ] || [ "$checksum_matches" != "yes" ]; then
      echo "rebuilding base image"
      {{ container_build_command }} files-for-image \
        -f base.Containerfile \
        --tag wsl-base:{{ version }}-{{ base_name }} \
        {{ base_build_args }} 2>&1 | tee base.Containerfile.log
      sha256sum base.Containerfile > base.Containerfile.sha256
    else
      echo "skipping base image (no changes)"
    fi
  fi

  # VARIANT-BASE LAYER
  if [ "$build_variant_base" = true ]; then
    variant_base_image_exists=$({{ container_tool }} image exists wsl-{{ variant }}-base:{{ version }}-{{ base_name }} && echo -n "yes" || echo -n "no")
    variant_checksum_matches=$(sha256sum --check {{ variant }}-base.Containerfile.sha256 > /dev/null 2>&1 && echo -n "yes" || echo -n "no")

    # Only apply stage_arg if targeting variant-base layer
    variant_stage_arg=""
    if [ "$target_layer" = "variant-base" ] && [ -n "$stage_arg" ]; then
      variant_stage_arg="$stage_arg"
    fi

    if [ -n "$variant_stage_arg" ] || [ "$variant_base_image_exists" != "yes" ] || [ "$variant_checksum_matches" != "yes" ]; then
      echo "rebuilding {{ variant }}-base image$([ -n "$variant_stage_arg" ] && echo " to stage {{ stage }}" || echo "")"
      {{ container_build_command }} files-for-image-{{ variant }} \
        -f {{ variant }}-base.Containerfile \
        --tag wsl-{{ variant }}-base:{{ version }}-{{ base_name }} \
        {{ if variant == "dev" { dev_build_args } else if variant == "ai" { ai_build_args } else { min_build_args } }} \
        $variant_stage_arg 2>&1 | tee {{ variant }}-base.Containerfile.log

      if [ -z "$variant_stage_arg" ]; then
        sha256sum base.Containerfile {{ variant }}-base.Containerfile > {{ variant }}-base.Containerfile.sha256
      fi
    else
      echo "skipping {{ variant }}-base image (no changes)"
    fi
  fi

  # SHELL-TOOLS LAYER
  if [ "$build_shell_tools" = true ] && [ "$target_layer" != "variant-base" ]; then
    shell_tools_image_exists=$({{ container_tool }} image exists wsl-{{ variant }}-shell-tools:{{ version }}-{{ base_name }} && echo -n "yes" || echo -n "no")
    shell_tools_checksum_matches=$(sha256sum --check {{ variant }}-shell-tools.Containerfile.sha256 > /dev/null 2>&1 && echo -n "yes" || echo -n "no")

    # Only use stage_arg if targeting shell-tools layer specifically
    shell_stage_arg=""
    if [ "$target_layer" = "shell-tools" ] && [ -n "$stage_arg" ]; then
      shell_stage_arg="$stage_arg"
    fi

    if [ -n "$shell_stage_arg" ] || [ "$shell_tools_image_exists" != "yes" ] || [ "$shell_tools_checksum_matches" != "yes" ]; then
      echo "rebuilding {{ variant }}-shell-tools image$([ -n "$shell_stage_arg" ] && echo " to stage {{ stage }}" || echo "")"
      {{ container_build_command }} files-for-image-{{ variant }} \
        -f shell-tools.Containerfile \
        --tag wsl-{{ variant }}-shell-tools:{{ version }}-{{ base_name }} \
        --build-arg BASE_IMAGE=wsl-base:{{ version }}-{{ base_name }} \
        --build-arg VARIANT_BASE_IMAGE=wsl-{{ variant }}-base:{{ version }}-{{ base_name }} \
        {{ shell_tools_build_args }} \
        $shell_stage_arg 2>&1 | tee shell-tools.Containerfile.log

      if [ -z "$shell_stage_arg" ]; then
        sha256sum base.Containerfile {{ variant }}-base.Containerfile shell-tools.Containerfile > {{ variant }}-shell-tools.Containerfile.sha256
      fi
    else
      echo "skipping {{ variant }}-shell-tools image (no changes)"
    fi
  fi

  # SHELL LAYER (no stages in shell.Containerfile, so no stage_arg applied)
  if [ "$build_shell" = true ]; then
    echo "building {{ variant }}-shell image"
    {{ container_build_command }} files-for-image-{{ variant }} \
      -f shell.Containerfile \
      --tag wsl-{{ variant }}:{{ version }}-{{ base_name }} \
      --build-arg SHELL_TOOLS_IMAGE=wsl-{{ variant }}-shell-tools:{{ version }}-{{ base_name }} \
      2>&1 | tee shell.Containerfile.log
  fi

  rm -rf files-for-image-{{ variant }}

build-tar variant="dev":
  rm -rf .build-{{ variant }} && mkdir .build-{{ variant }}

  # copy recursive including hidden files
  rsync -ax files-for-tar/ .build-{{ variant }}/

  sed -i 's/@@ name @/{{ version }}-{{ variant }}-{{ base_name }}/g' .build-{{ variant }}/import.cmd
  sed -i 's/@@ name @/{{ version }}-{{ variant }}-{{ base_name }}/g' .build-{{ variant }}/unregister.cmd

  mv .build-{{ variant }}/import.cmd .build-{{ variant }}/{{ version }}-{{ variant }}-{{ base_name }}-import.cmd
  mv .build-{{ variant }}/unregister.cmd .build-{{ variant }}/{{ version }}-{{ variant }}-{{ base_name }}-unregister.cmd

build variant="dev":
  just build-tar {{variant}}
  just build-image {{variant}}

run variant="dev":
  {{ container_tool }} run \
    -it \
    --rm \
    -e TERM="xterm-256color" \
    --name wsl-{{ variant }}-{{ version }}-{{ base_name }} \
    --user=$(id -u) \
    --userns=keep-id:size=1000 \
    wsl-{{ variant }}:{{ version }}-{{ base_name }} \
    zsh || true

export variant="dev":
  #!/usr/bin/env bash
  set -euo pipefail

  image_size=$({{ container_tool }} image inspect wsl-{{ variant }}:{{ version }}-{{ base_name }} | jq '.[].Size')

  {{ container_tool }} rm -f wsl-{{ variant }}-{{ version }}-{{ base_name }} > /dev/null 2>&1
  {{ container_tool }} run --name wsl-{{ variant }}-{{ version }}-{{ base_name }} -d wsl-{{ variant }}:{{ version }}-{{ base_name }} sleep infinity
  {{ container_tool }} export wsl-{{ variant }}-{{ version }}-{{ base_name }} | pv -s $image_size > .build-{{ variant }}/{{ version }}-{{ variant }}-{{ base_name }}.tar
  {{ container_tool }} stop wsl-{{ variant }}-{{ version }}-{{ base_name }} -t 1
  {{ container_tool }} rm wsl-{{ variant }}-{{ version }}-{{ base_name }}

package variant="dev":
  rm -f .build-{{ variant }}/wsl-{{ variant }}-{{ version }}-{{ base_name }}.tar.gz
  tar cf - .build-{{ variant }}/ -P | \
    pv -s $(du -sb .build-{{ variant }} | \
    awk '{print $1}') | \
    gzip > wsl-{{ variant }}-{{ version }}-{{ base_name }}.tar.gz && \
    mv wsl-{{ variant }}-{{ version }}-{{ base_name }}.tar.gz .build-{{ variant }}/

build-agent-base-image:
  #!/usr/bin/env bash
  set -euo pipefail
  CURRENT_USER=$(whoami)
  CURRENT_UID=$(id -u)
  CURRENT_GID=$(id -g)
  rm -rf .image-build
  mkdir .image-build
  podman build \
  -f .tools/agent-base.Containerfile \
  -t wsl-agent-base:latest \
  --build-arg USER_NAME=${CURRENT_USER} \
  --build-arg USER_UID=${CURRENT_UID} \
  --build-arg USER_GID=${CURRENT_GID} \
  .image-build
  rm -rf .image-build

# https://www.npmjs.com/package/@anthropic-ai/claude-code?activeTab=versions
build-agent-claude-code: build-agent-base-image
  #!/usr/bin/env bash
  set -euo pipefail
  CURRENT_USER=$(whoami)
  rm -rf .image-build
  mkdir .image-build
  podman build \
  -f .tools/claude-code.Containerfile \
  -t wsl-agent-claude-code:latest \
  --build-arg USER_NAME=${CURRENT_USER} \
  --build-arg TOOL_VERSION=2.0.59 \
  .image-build
  rm -rf .image-build
