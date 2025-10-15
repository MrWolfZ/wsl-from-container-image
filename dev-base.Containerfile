ARG WSL_BASE_IMAGE
FROM ${WSL_BASE_IMAGE} as base

# install additional tools for C development (useful for building other projects from source)
RUN apt-get update && \
    apt-get install -y \
    btrfs-progs \
    iptables \
    libassuan-dev \
    libbtrfs-dev \
    libc6-dev \
    libcap-dev \
    libdevmapper-dev \
    libglib2.0-dev \
    libgpg-error-dev \
    libgpgme-dev \
    libprotobuf-c-dev \
    libprotobuf-dev \
    libseccomp-dev \
    libselinux1-dev \
    libslirp-dev \
    libsystemd-dev \
    libtool \
    libyajl-dev \
    passt \
    pkg-config \
    pkgconf \
    protobuf-compiler \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tools for rust development, specifically for compiling
# software for ARM64 devices
RUN apt-get update && \
    apt-get install -y \
    g++-aarch64-linux-gnu \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabihf \
    libc6-armhf-cross \
    libc6-dev-armhf-cross \
    musl-dev \
    musl-tools \
    qemu-user-static \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tools for java development
RUN apt-get update && \
    apt-get install -y \
    openjdk-17-jdk \
    openjdk-21-jdk \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tools for dotnet development
RUN add-apt-repository ppa:dotnet/backports && \
    apt-get update && \
    apt-get install -y \
    dotnet-sdk-8.0 \
    dotnet-sdk-9.0 \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

COPY wsl.conf /etc/wsl.conf

# run the rest of the setup as the dev user
USER dev
SHELL ["/bin/bash", "-c"]
WORKDIR /home/dev

FROM base as base-golang

# install tools for go development (rename go dir to golang to work around `make` issue when a `go` dir is in path)
ARG GO_VERSION
RUN curl -fLO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C . -xf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz && \
    mv go "$HOME/.golang" && \
    "$HOME/.golang/bin/go" version

FROM base as base-rust

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path && \
    "$HOME/.cargo/bin/rustup" -v component add rustfmt && \
    "$HOME/.cargo/bin/rustup" -v component add clippy && \
    "$HOME/.cargo/bin/rustup" -v target add x86_64-unknown-linux-musl && \
    "$HOME/.cargo/bin/rustup" -v target add aarch64-unknown-linux-musl && \
    "$HOME/.cargo/bin/rustup" -v completions zsh > ~/.config/zsh/completions/_rustup && \
    "$HOME/.cargo/bin/rustup" -v completions zsh cargo > ~/.config/zsh/completions/_cargo && \
    "$HOME/.cargo/bin/rustup" -v --version && \
    "$HOME/.cargo/bin/cargo" --version

FROM base as base-python

# install tools for go development (rename go dir to golang to work around `make` issue when a `go` dir is in path)
ARG UV_VERSION
ARG PYTHON_VERSION
RUN curl -fLO "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz" && \
    curl -fLO "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz.sha256" && \
    sha256sum --check uv*.sha256 && rm uv*.sha256 && \
    mkdir uv && \
    tar -C uv -xf uv*.tar.gz && \
    rm uv*.tar.gz && \
    mv uv/uv-*/* "$HOME/.local/bin/" && \
    rm -rf uv && \
    PATH="$HOME/.local/bin:$PATH" uv python install $PYTHON_VERSION --default && \
    PATH="$HOME/.local/bin:$PATH" uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv

FROM base as base-node

ARG FNM_VERSION
RUN curl -fLO "https://github.com/Schniz/fnm/releases/download/${FNM_VERSION}/fnm-linux.zip" && \
    unzip fnm-linux.zip && \
    rm fnm-linux.zip && \
    mv fnm "$HOME/.local/bin/" && \
    "$HOME/.local/bin/fnm" completions --shell zsh > "$HOME/.config/zsh/completions/_fnm" && \
    export PATH="$HOME/.local/bin:$PATH" && \
    eval "$(fnm env --use-on-cd)" && \
    fnm install --lts && \
    fnm install --latest && \
    fnm default latest && \
    printf '#compdef npm\n_npm_completion() {\n  local si=$IFS\n  compadd -- $(COMP_CWORD=$((CURRENT-1)) COMP_LINE=$BUFFER COMP_POINT=0 npm completion -- "${words[@]}" 2>/dev/null)\n  IFS=$si\n}\ncompdef _npm_completion npm\n' > "$HOME/.config/zsh/completions/_npm" && \
    curl -fLo "$HOME/.config/zsh/completions/_node" "https://raw.githubusercontent.com/zsh-users/zsh-completions/master/src/_node" && \
    echo "changeme" | sudo -S rm -rf /tmp/*

FROM base-golang as base-containernetworking

ARG CONTAINERNETWORKING_VERSION
RUN cd "$HOME/src" && \
    git clone https://github.com/containernetworking/plugins -b $CONTAINERNETWORKING_VERSION --depth 1 -c advice.detachedHead=false && \
    mv plugins containernetworking-plugins && \
    cd containernetworking-plugins && \
    export GOCACHE="$PWD/.gocache" && \
    export PATH="$HOME/.golang/bin:$PATH" && \
    ./build_linux.sh && \
    echo "changeme" | sudo -S mkdir -p /opt/cni/bin && \
    echo "changeme" | sudo -S cp bin/* /opt/cni/bin/ && \
    echo "changeme" | sudo -S chown root:root /opt/cni/bin/ && \
    git clean -dffx && git submodule foreach --recursive git clean -dffx && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    rm -rf "$HOME/go"

FROM base as base-slirp4netns

ARG SLIRP4NETNS_VERSION
RUN cd "$HOME/src" && \
    git clone https://github.com/rootless-containers/slirp4netns -b $SLIRP4NETNS_VERSION --depth 1 -c advice.detachedHead=false && \
    cd slirp4netns && \
    ./autogen.sh && \
    ./configure --prefix="$HOME/.local" && \
    make && \
    make install && \
    git clean -dffx && git submodule foreach --recursive git clean -dffx && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    PATH="$HOME/.local/bin:$PATH" slirp4netns --version

FROM base as base-conmon

ARG CONMON_VERSION
RUN cd "$HOME/src" && \
    git clone https://github.com/containers/conmon -b $CONMON_VERSION --depth 1 -c advice.detachedHead=false && \
    cd conmon && \
    make && \
    make PREFIX="$HOME/.local" install.bin && \
    git clean -dffx && git submodule foreach --recursive git clean -dffx && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    PATH="$HOME/.local/bin:$PATH" conmon --version

FROM base-rust as base-netavark

ARG NETAVARK_VERSION
RUN cd "$HOME/src" && \
    git clone https://github.com/containers/netavark -b $NETAVARK_VERSION --depth 1 -c advice.detachedHead=false && \
    cd netavark && \
    export PATH="$HOME/.cargo/bin:$PATH" && \
    sed -i 's/$(MAKE) -C docs install/#$(MAKE) -C docs install/' Makefile && \
    make build && \
    make PREFIX="$HOME/.local" install && \
    git clean -dffx && git submodule foreach --recursive git clean -dffx && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    PATH="$HOME/.local/libexec/podman:$PATH" netavark --version

FROM base-rust as base-aardvark-dns

ARG AARDVARK_DNS_VERSION
RUN cd "$HOME/src" && \
    git clone https://github.com/containers/aardvark-dns -b $AARDVARK_DNS_VERSION --depth 1 -c advice.detachedHead=false && \
    cd aardvark-dns && \
    export PATH="$HOME/.cargo/bin:$PATH" && \
    make && \
    make PREFIX="$HOME/.local" install && \
    git clean -dffx && git submodule foreach --recursive git clean -dffx && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    PATH="$HOME/.local/libexec/podman:$PATH" aardvark-dns --version

FROM base as base-crun

ARG CRUN_VERSION
RUN cd "$HOME/src" && \
    git clone https://github.com/containers/crun -b $CRUN_VERSION --depth 1 -c advice.detachedHead=false && \
    cd crun && \
    ./autogen.sh && \
    ./configure --prefix="$HOME/.local" && \
    make && \
    make install && \
    git clean -dffx && git submodule foreach --recursive git clean -dffx && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    PATH="$HOME/.local/bin:$PATH" crun --version

FROM base-golang as base-podman

ARG PODMAN_VERSION
RUN cd "$HOME/src" && \
    git clone https://github.com/containers/podman -b $PODMAN_VERSION --depth 1 -c advice.detachedHead=false && \
    cd podman && \
    export GOCACHE="$PWD/.gocache" && \
    export PATH="$HOME/.golang/bin:$PATH" && \
    make BUILDTAGS="apparmor cni exclude_graphdriver_devicemapper selinux seccomp systemd" && \
    env "PATH=$HOME/.golang/bin:$PATH" make PREFIX="$HOME/.local" install && \
    mkdir -p "$HOME/.local/share/systemd/user" && \
    mv "$HOME/.local/lib/systemd/user/"* "$HOME/.local/share/systemd/user/" && \
    git clean -dffx && git submodule foreach --recursive git clean -dffx && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    rm -rf "$HOME/go" && \
    PATH="$HOME/.local/bin:$PATH" podman --version && \
    PATH="$HOME/.local/bin:$PATH" podman-remote --version && \
    PATH="$HOME/.local/bin:$PATH" podman completion zsh >  "$HOME/.config/zsh/completions/_podman" && \
    PATH="$HOME/.local/bin:$PATH" podman-remote completion zsh >  "$HOME/.config/zsh/completions/_podman-remote"

FROM base-python as base-podman-compose

RUN export PATH="$HOME/.local/bin:$PATH" && \
    uv venv && \
    source .venv/bin/activate && \
    uv pip install pyinstaller && \
    curl -fLO https://raw.githubusercontent.com/containers/podman-compose/main/requirements.txt && \
    curl -fLO https://raw.githubusercontent.com/containers/podman-compose/main/podman_compose.py && \
    uv pip install -r requirements.txt && \
    pyinstaller --onefile --clean podman_compose.py && \
    cp dist/podman_compose "$HOME/.local/bin/podman-compose" && \
    chmod +x "$HOME/.local/bin/podman-compose"

FROM base-golang as base-dive

ARG DIVE_VERSION
RUN cd "$HOME/src" && \
    git clone https://github.com/wagoodman/dive.git -b $DIVE_VERSION --depth 1 -c advice.detachedHead=false && \
    cd dive && \
    export GOCACHE="$PWD/.gocache" && \
    export PATH="$HOME/.golang/bin:$PATH" && \
    make bootstrap && \
    echo "release: { prerelease: auto, draft: false }" > .goreleaser.yaml && \
    echo "builds: [{ binary: dive, env: [CGO_ENABLED=0], goos: [linux], goarch: [amd64], ldflags: '-s -w -X main.version={{.Version}} -X main.commit={{.Commit}} -X main.buildTime={{.Date}}' }]" >> .goreleaser.yaml && \
    make build && \
    mv snapshot/dive_linux_amd64_v1/dive "$HOME/.local/bin/" && \
    git clean -dffx && git submodule foreach --recursive git clean -dffx && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    echo "changeme" | sudo -S rm -rf "$HOME/go"

FROM base as base-lazydocker

ARG LAZYDOCKER_VERSION
RUN curl -fLO "https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION#v}_Linux_x86_64.tar.gz" && \
    curl -fLO "https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/checksums.txt" && \
    sha256sum --check --ignore-missing checksums.txt && rm checksums.txt && \
    mkdir lazydocker && \
    tar xzf lazydocker*.tar.gz -C ./lazydocker && \
    mv ./lazydocker/lazydocker "$HOME/.local/bin/" && \
    rm lazydocker*.tar.gz && \
    rm -rf lazydocker && \
    "$HOME/.local/bin/lazydocker" --version

FROM base as base-container-tools

# note that we can unfortunately not use $HOME in the target directories for
# COPY commands, so we have to hardcode the user name

COPY --from=base-containernetworking --chown=root:root /opt/cni/bin /opt/cni/bin

COPY --from=base-slirp4netns --chown=root:root /home/dev/.local/bin/slirp4netns /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" slirp4netns --version

COPY --from=base-conmon --chown=root:root /home/dev/.local/bin/conmon /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" conmon --version

COPY --from=base-netavark --chown=root:root /home/dev/.local/libexec/podman/netavark /home/dev/.local/libexec/podman/
RUN PATH="$HOME/.local/libexec/podman:$PATH" netavark --version

COPY --from=base-aardvark-dns --chown=root:root /home/dev/.local/libexec/podman/aardvark-dns /home/dev/.local/libexec/podman/
RUN PATH="$HOME/.local/libexec/podman:$PATH" aardvark-dns --version

COPY --from=base-crun --chown=root:root /home/dev/.local/bin/crun /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" crun --version

COPY --from=base-podman --chown=root:root /home/dev/.local/bin/podman* /home/dev/.local/bin/
COPY --from=base-podman --chown=root:root /home/dev/.local/libexec/podman/ /home/dev/.local/libexec/podman/
COPY --from=base-podman --chown=root:root /home/dev/.local/share/systemd/user/ /home/dev/.local/share/systemd/user/
COPY --from=base-podman --chown=root:root /home/dev/.local/share/man/man1/ /home/dev/.local/share/man/man1/
COPY --from=base-podman --chown=root:root /home/dev/.local/share/man/man5/ /home/dev/.local/share/man/man5/
COPY --from=base-podman --chown=root:root /home/dev/.local/share/man/man7/ /home/dev/.local/share/man/man7/
COPY --from=base-podman --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" podman --version && PATH="$HOME/.local/bin:$PATH" podman-remote --version

COPY --from=base-podman-compose --chown=root:root /home/dev/.local/bin/podman-compose /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" podman-compose --version

# configure tools required by podman
RUN echo "changeme" | sudo -S chmod u-s /usr/bin/new[gu]idmap && \
    echo "changeme" | sudo -S setcap cap_setuid=ep /usr/bin/newuidmap && \
    echo "changeme" | sudo -S setcap cap_setgid=ep /usr/bin/newgidmap

COPY --chown=root:root containers.conf registries.conf policy.json /home/dev/.config/containers/

# enable the podman socket service so that other tools can use its docker-compatible API
RUN systemctl enable --user podman.socket && \
    systemctl enable --user podman.service

# create systemd drop-in to set PATH for podman services so they can find helper binaries
RUN mkdir -p "$HOME/.config/systemd/user/podman.service.d" && \
    printf '[Service]\nEnvironment="PATH=/home/dev/.local/bin:/home/dev/.local/libexec/podman:/usr/local/bin:/usr/bin:/bin"\n' > "$HOME/.config/systemd/user/podman.service.d/path.conf" && \
    mkdir -p "$HOME/.config/systemd/user/podman.socket.d" && \
    printf '[Service]\nEnvironment="PATH=/home/dev/.local/bin:/home/dev/.local/libexec/podman:/usr/local/bin:/usr/bin:/bin"\n' > "$HOME/.config/systemd/user/podman.socket.d/path.conf"

# configure cgroup delegation for k3s rootless mode
RUN echo "changeme" | sudo -S mkdir -p /etc/systemd/system/user@.service.d
COPY --chown=root:root etc/systemd/system/user@.service.d/delegate.conf /etc/systemd/system/user@.service.d/delegate.conf

FROM base as base-just

ARG JUST_VERSION
RUN echo "changeme" | sudo -S mkdir -p /usr/local/share/man/man1/ && \
    curl -fLO "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
    curl -fLO "https://github.com/casey/just/releases/download/${JUST_VERSION}/SHA256SUMS" && \
    sha256sum --check --ignore-missing SHA256SUMS && rm SHA256SUMS && \
    mkdir just && \
    tar xzf just*.tar.gz -C ./just && \
    mv ./just/just "$HOME/.local/bin/" && \
    mv ./just/completions/just.zsh "$HOME/.config/zsh/completions/_just" && \
    echo "changeme" | sudo -S mv ./just/just.1 /usr/local/share/man/man1/ && \
    rm just*.tar.gz && \
    rm -rf just

FROM base as base-kubectl

ARG KUBECTL_VERSION
RUN curl -fLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    curl -fLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && rm kubectl.sha256 && \
    chmod +x kubectl && \
    mv ./kubectl "$HOME/.local/bin/kubectl" && \
    "$HOME/.local/bin/kubectl" completion zsh > "$HOME/.config/zsh/completions/_kubectl"

FROM base as base-kubectx

RUN curl -fLo "$HOME/.local/bin/kubectx" "https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/kubectx" && \
    curl -fLo "$HOME/.local/bin/kubens" "https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/kubens" && \
    chmod +x "$HOME/.local/bin/kubectx" && \
    chmod +x "$HOME/.local/bin/kubens" && \
    curl -fLo "$HOME/.config/zsh/completions/_kubectx" "https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/completion/_kubectx.zsh" && \
    curl -fLo "$HOME/.config/zsh/completions/_kubens" "https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/completion/_kubens.zsh"

FROM base as base-kubetail

RUN curl -fLo "$HOME/.local/bin/kubetail" "https://github.com/johanhaleby/kubetail/raw/refs/heads/master/kubetail" && \
    chmod +x "$HOME/.local/bin/kubetail" && \
    curl -fLo "$HOME/.config/zsh/completions/_kubetail" "https://raw.githubusercontent.com/johanhaleby/kubetail/refs/heads/master/completion/kubetail.zsh"

FROM base as base-helm

ARG HELM_VERSION
RUN curl -fLO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    curl -fLO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" && \
    sha256sum --check helm*.sha256sum && rm helm*.sha256sum && \
    mkdir helm && \
    tar xzf helm*.tar.gz -C ./helm && \
    mv ./helm/linux-amd64/helm "$HOME/.local/bin/helm" && \
    rm helm*.tar.gz && \
    rm -rf helm && \
    "$HOME/.local/bin/helm" completion zsh > "$HOME/.config/zsh/completions/_helm"

FROM base as base-kubelogin

ARG KUBELOGIN_VERSION
RUN curl -fLO "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip" && \
    curl -fLO "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip.sha256" && \
    cat kubelogin-linux-amd64.zip.sha256 | sha256sum --check && \
    rm kubelogin-linux-amd64.zip.sha256 && \
    unzip kubelogin-linux-amd64.zip -d ./kubelogin && \
    rm kubelogin-linux-amd64.zip && \
    chmod +x kubelogin/bin/linux_amd64/kubelogin && \
    mv ./kubelogin/bin/linux_amd64/kubelogin "$HOME/.local/bin/kubelogin" && \
    rm -rf ./kubelogin

FROM base as base-clusterctl

ARG CLUSTERCTL_VERSION
RUN curl -fLo clusterctl "https://github.com/kubernetes-sigs/cluster-api/releases/download/${CLUSTERCTL_VERSION}/clusterctl-linux-amd64" && \
    chmod +x clusterctl && \
    mv ./clusterctl "$HOME/.local/bin/clusterctl" && \
    "$HOME/.local/bin/clusterctl" completion zsh > "$HOME/.config/zsh/completions/_clusterctl"

FROM base as base-cilium

ARG CILIUM_VERSION
RUN export CLI_ARCH=amd64 && \
    curl -fL --remote-name-all "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}" && \
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum && \
    tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz "$HOME/.local/bin" && \
    rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} && \
    "$HOME/.local/bin/cilium" completion zsh > "$HOME/.config/zsh/completions/_cilium"

FROM base as base-hubble

ARG HUBBLE_VERSION
RUN export HUBBLE_ARCH=amd64 && \
    curl -fL --remote-name-all "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}" && \
    sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum && \
    tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz "$HOME/.local/bin" && \
    rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum} && \
    "$HOME/.local/bin/hubble" completion zsh > "$HOME/.config/zsh/completions/_hubble"

FROM base as base-kind

ARG KIND_VERSION
RUN curl -fLo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64" && \
    chmod +x ./kind && \
    mv ./kind "$HOME/.local/bin/kind" && \
    "$HOME/.local/bin/kind" completion zsh > "$HOME/.config/zsh/completions/_kind"

FROM base as base-k3s

ARG K3S_VERSION
RUN curl -fLO "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s" && \
    curl -fLO "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/sha256sum-amd64.txt" && \
    sha256sum --check --ignore-missing sha256sum-amd64.txt && rm sha256sum-amd64.txt && \
    chmod +x ./k3s && \
    mv ./k3s "$HOME/.local/bin/k3s" && \
    "$HOME/.local/bin/k3s" completion zsh > "$HOME/.config/zsh/completions/_k3s"

FROM base as base-kubebuilder

ARG KUBEBUILDER_VERSION
RUN curl -fLo kubebuilder "https://github.com/kubernetes-sigs/kubebuilder/releases/download/${KUBEBUILDER_VERSION}/kubebuilder_linux_amd64" && \
    chmod +x ./kubebuilder && \
    mv ./kubebuilder "$HOME/.local/bin/kubebuilder" && \
    "$HOME/.local/bin/kubebuilder" completion zsh > "$HOME/.config/zsh/completions/_kubebuilder"

FROM base as base-vault

ARG VAULT_VERSION
RUN curl -fLo vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" && \
    unzip vault.zip -d ./vault && \
    rm vault.zip && \
    chmod +x vault/vault && \
    mv ./vault/vault "$HOME/.local/bin/vault" && \
    rm -rf ./vault && \
    echo 'complete -o nospace -C /home/dev/.local/bin/vault vault' > "$HOME/.config/zsh/bash_completions/vault.completion"

FROM base as base-kubeseal

ARG KUBESEAL_VERSION
RUN curl -fLo kubeseal.tar.gz "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz" && \
    tar -xvzf kubeseal.tar.gz kubeseal && \
    rm kubeseal.tar.gz && \
    chmod +x kubeseal && \
    mv ./kubeseal "$HOME/.local/bin/kubeseal" && \
    "$HOME/.local/bin/kubeseal" --version > /dev/null

FROM base as base-mc

ARG MC_VERSION
RUN curl -fLo "$HOME/.local/bin/mc" "https://dl.min.io/client/mc/release/linux-amd64/archive/mc.${MC_VERSION}" && \
    chmod +x "$HOME/.local/bin/mc" && \
    "$HOME/.local/bin/mc" --help > /dev/null && \
    echo 'complete -o nospace -C /home/dev/.local/bin/mc mc' > "$HOME/.config/zsh/bash_completions/mc.completion"

FROM base as base-k9s

ARG K9S_VERSION
RUN curl -fLO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" && \
    curl -fLO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/checksums.sha256" && \
    sha256sum --check --ignore-missing checksums.sha256 && rm checksums.sha256 && \
    mkdir k9s && \
    tar xzf k9s*.tar.gz -C ./k9s && \
    mv ./k9s/k9s "$HOME/.local/bin/" && \
    rm k9s*.tar.gz && \
    rm -rf k9s && \
    "$HOME/.local/bin/k9s" completion zsh > "$HOME/.config/zsh/completions/_k9s"

FROM base-container-tools as base-tools

# note that we can unfortunately not use $HOME in the target directories for
# COPY commands, so we have to hardcode the user name

COPY --from=base-golang --chown=dev:dev /home/dev/.golang /home/dev/.golang
RUN echo "changeme" | sudo -S chown -R root:root "$HOME/.golang/bin" && \
    PATH="$HOME/.golang/bin:$PATH" go version

COPY --from=base-rust --chown=dev:dev /home/dev/.cargo /home/dev/.cargo
COPY --from=base-rust --chown=dev:dev /home/dev/.rustup /home/dev/.rustup
COPY --from=base-rust --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN echo "changeme" | sudo -S chown -R root:root "$HOME/.cargo/bin" && \
    echo "changeme" | sudo -S chown -R root:root "$HOME/.rustup/toolchains" && \
    PATH="$HOME/.cargo/bin:$PATH" cargo --version

COPY --from=base-python --chown=root:root /home/dev/.local/bin/uv* /home/dev/.local/bin/
COPY --from=base-python --chown=root:root /home/dev/.local/bin/python* /home/dev/.local/bin/
COPY --from=base-python --chown=dev:dev /home/dev/.local/share/uv /home/dev/.local/share/uv
COPY --from=base-python --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN export PATH="$HOME/.local/bin:$PATH" && uv --version && python --version

# install the Azure CLI directly into the final image to prevent some path issues
RUN export PATH="$HOME/.local/bin:$PATH" && \
    uv tool install azure-cli --prerelease=allow && \
    curl -fLo /home/dev/.config/zsh/bash_completions/az.completion https://raw.githubusercontent.com/Azure/azure-cli/dev/az.completion

COPY --from=base-node --chown=root:root /home/dev/.local/bin/fnm /home/dev/.local/bin/
COPY --from=base-node --chown=dev:dev /home/dev/.local/share/fnm /home/dev/.local/share/fnm
COPY --from=base-node --chown=root:root /home/dev/.config/zsh/completions/_fnm /home/dev/.config/zsh/completions/
RUN export PATH="$HOME/.local/bin:$PATH" && eval "$(fnm env --use-on-cd)" && node -v

COPY --from=base-dive --chown=root:root /home/dev/.local/bin/dive /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" dive --version

COPY --from=base-lazydocker --chown=root:root /home/dev/.local/bin/lazydocker /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" lazydocker --version

COPY --from=base-just --chown=root:root /home/dev/.local/bin/just /home/dev/.local/bin/
COPY --from=base-just --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
COPY --from=base-just --chown=root:root /usr/local/share/man/man1/just.1 /usr/local/share/man/man1/
RUN PATH="$HOME/.local/bin:$PATH" just --version

COPY --from=base-kubectl --chown=root:root /home/dev/.local/bin/kubectl /home/dev/.local/bin/
COPY --from=base-kubectl --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" kubectl version --client

COPY --from=base-kubectx --chown=root:root /home/dev/.local/bin/kube* /home/dev/.local/bin/
COPY --from=base-kubectx --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN export PATH="$HOME/.local/bin:$PATH" && kubectx --help && kubens --help

COPY --from=base-kubetail --chown=root:root /home/dev/.local/bin/kubetail /home/dev/.local/bin/
COPY --from=base-kubetail --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" kubetail --version

COPY --from=base-helm --chown=root:root /home/dev/.local/bin/helm /home/dev/.local/bin/
COPY --from=base-helm --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" helm version

COPY --from=base-kubelogin --chown=root:root /home/dev/.local/bin/kubelogin /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" kubelogin --version

COPY --from=base-clusterctl --chown=root:root /home/dev/.local/bin/clusterctl /home/dev/.local/bin/
COPY --from=base-clusterctl --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" clusterctl version

COPY --from=base-cilium --chown=root:root /home/dev/.local/bin/cilium /home/dev/.local/bin/
COPY --from=base-cilium --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" cilium version --client

COPY --from=base-hubble --chown=root:root /home/dev/.local/bin/hubble /home/dev/.local/bin/
COPY --from=base-hubble --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" hubble --version

COPY --from=base-kind --chown=root:root /home/dev/.local/bin/kind /home/dev/.local/bin/
COPY --from=base-kind --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" kind --version

COPY --from=base-k3s --chown=root:root /home/dev/.local/bin/k3s /home/dev/.local/bin/
COPY --from=base-k3s --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" k3s --version

COPY --from=base-kubebuilder --chown=root:root /home/dev/.local/bin/kubebuilder /home/dev/.local/bin/
COPY --from=base-kubebuilder --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" kubebuilder version

COPY --from=base-vault --chown=root:root /home/dev/.local/bin/vault /home/dev/.local/bin/
COPY --from=base-vault --chown=root:root /home/dev/.config/zsh/bash_completions/* /home/dev/.config/zsh/bash_completions/
RUN PATH="$HOME/.local/bin:$PATH" vault --version

COPY --from=base-kubeseal --chown=root:root /home/dev/.local/bin/kubeseal /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" kubeseal --version

COPY --from=base-mc --chown=root:root /home/dev/.local/bin/mc /home/dev/.local/bin/
COPY --from=base-mc --chown=root:root /home/dev/.config/zsh/bash_completions/* /home/dev/.config/zsh/bash_completions/
RUN PATH="$HOME/.local/bin:$PATH" mc --version

COPY --from=base-k9s --chown=root:root /home/dev/.local/bin/k9s /home/dev/.local/bin/
COPY --from=base-k9s --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" k9s version

FROM base-tools

RUN rm .sudo_as_admin_successful || true
