FROM ubuntu:24.04

# create an initial fully upgraded ubuntu installation
RUN export TIMEZONE=Europe/Zurich && \
    export DEBIAN_FRONTEND=noninteractive && \
    \
    # during later steps ubuntu wants to know the console encoding interactively, so we pre-populate it
    echo "console-setup   console-setup/charmap47 select  UTF-8" > encoding.conf && \
    debconf-set-selections encoding.conf && \
    rm encoding.conf && \
    \
    # during later steps ubuntu wants to know the time zone interactively, so we pre-populate it
    ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
    echo $TIMEZONE > /etc/timezone && \
    \
    # finally we can install various ubuntu packages to install all the default tools
    apt-get update && \
    apt-get install -y ubuntu-minimal ubuntu-server ubuntu-standard ubuntu-wsl && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# configure additional OS settings
RUN export TIMEZONE=Europe/Zurich && \
    export DEBIAN_FRONTEND=noninteractive && \
    locale-gen "en_US" && \
    locale-gen "en_US.UTF-8" && \
    dpkg-reconfigure locales && \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 && \
    rm -rf /var/cache/debconf/*

# install general tools
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    apt-utils \
    bash-completion \
    build-essential \
    ca-certificates \
    gdb \
    gddrescue \
    git \
    gnupg \
    htop \
    lsb-release \
    nano \
    openssh-server \
    pv \
    unzip \
    zip \
    zsh && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# configure SSH
RUN systemctl enable ssh && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# install tools for C development (useful for building other projects from source)
RUN apt-get update && \
    apt-get install -y \
    autoconf \
    automake \
    btrfs-progs \
    build-essential \
    containernetworking-plugins \
    gcc \
    git \
    go-md2man \
    golang-go \
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
    libsystemd-dev \
    libtool \
    libyajl-dev \
    make \
    passt \
    pkg-config \
    pkgconf \
    protobuf-compiler \
    python3 \
    runc \
    slirp4netns \
    uidmap && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tools for Azure development
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tools for dotnet development
RUN add-apt-repository ppa:dotnet/backports && \
    apt-get update && \
    apt-get install -y \
    dotnet-sdk-6.0 \
    dotnet-sdk-7.0 \
    dotnet-sdk-8.0 && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tools for java development
RUN apt-get update && \
    apt-get install -y \
    openjdk-17-jdk \
    openjdk-21-jdk && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tools for rust development
RUN apt-get update && \
    apt-get install -y \
    g++-aarch64-linux-gnu \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabihf \
    libc6-armhf-cross \
    libc6-dev-armhf-cross \
    musl-dev \
    musl-tools \
    qemu-user-static && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tools for python development
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
    python3 \
    python3-venv \
    python3.12 \
    python3.12-venv && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install tool to create user (specifically mkpasswd included in the whois package
RUN apt-get update && \
    apt-get install -y \
    whois && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# run one last upgrade to ensure everything is up to date
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

COPY wsl.conf.copy /etc/wsl.conf

# delete the default ubuntu user and create a dedicated dev user
RUN userdel ubuntu && \
    rm -rf /home/ubuntu && \
    export PASSWORD=$(mkpasswd -m sha512crypt changeme) && \
    groupadd dev --gid 1000 && \
    useradd dev \
    --uid 1000 \
    --gid 1000 \
    --password $PASSWORD \
    --shell $(which zsh) \
    --create-home && \
    usermod -aG sudo dev && \
    # add bigger id ranges for the dev user for podman containers with
    # a lot of files (note that we write directly to the files instead
    # of using usermod since the latter creates multiple entries in the
    # files, which breaks podman
    echo "dev:100000:565536" > /etc/subgid && \
    echo "dev:100000:565536" > /etc/subuid

RUN chown -R dev:dev /home/dev/

# run the rest of the setup as the dev user
USER dev
SHELL ["/bin/bash", "-c"]
WORKDIR /home/dev

# create some default directories
RUN mkdir ~/src

# configure shell
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    rm -f ~/.zshrc.pre-oh-my-zsh && \
    rm -f ~/.zsh_history && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k && \
    mkdir -p $HOME/.cache/gitstatus && \
    curl -LO https://github.com/romkatv/gitstatus/releases/download/v1.5.4/gitstatusd-linux-x86_64.tar.gz && \
    tar -C $HOME/.cache/gitstatus -xvf gitstatusd-linux-x86_64.tar.gz && \
    chmod +x $HOME/.cache/gitstatus/gitstatusd-linux-x86_64 && \
    rm gitstatusd-linux-x86_64.tar.gz && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# direnv
RUN mkdir -p ~/.local/bin && \
    export bin_path=~/.local/bin && \
    curl -sfL https://direnv.net/install.sh | bash && \
    ~/.local/bin/direnv --version && \
    mkdir -p ~/.config/direnv && \
    echo -e "strict_env\nDIRENV_LOG_FORMAT=" | tee ~/.config/direnv/direnvrc

# install tools for node development
RUN export NVM_VERSION="v0.40.0" && \
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash && \
    source .nvm/nvm.sh && \
    nvm install stable && \
    nvm install --lts

# install tools for go development (rename go dir to golang to work around `make` issue when a `go` dir is in path)
RUN export GO_VERSION="1.23.0" && \
    mkdir -p ~/.local/bin && \
    curl -OL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C ~/.local/bin -xvf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz && \
    mv ~/.local/bin/go ~/.local/bin/golang

# we build crun from source since the ubuntu repositories are often lagging behind
RUN export CRUN_VERSION="1.16.1" && \
    echo "changeme" | sudo -S mkdir -p /etc/containers && \
    cd ~/src && \
    git clone https://github.com/containers/crun -b $CRUN_VERSION --depth 1 && \
    cd crun && \
    export GOCACHE="$PWD/.gocache" && \
    ./autogen.sh && \
    ./configure && \
    make && \
    echo "changeme" | sudo -S make install && \
    git clean -d -x -f && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    rm -rf ~/go

# we build conmon from source since the ubuntu repositories are often lagging behind
RUN export CONMON_VERSION="v2.1.12" && \
    cd ~/src && \
    git clone https://github.com/containers/conmon -b $CONMON_VERSION --depth 1 && \
    cd conmon && \
    export GOCACHE="$PWD/.gocache" && \
    make && \
    echo "changeme" | sudo -S make podman && \
    git clean -d -x -f && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    rm -rf ~/go

# we build netavark from source since the ubuntu repositories are often lagging behind
RUN export NETAVARK_VERSION="v1.13.1" && \
    cd ~/src && \
    git clone https://github.com/containers/netavark -b $NETAVARK_VERSION --depth 1 && \
    cd netavark && \
    make && \
    make docs && \
    echo "changeme" | sudo -S make install && \
    git clean -d -x -f && \
    echo "changeme" | sudo -S rm -rf /tmp/*

# we build aardvark-dns from source since the ubuntu repositories are often lagging behind
RUN export AARDVARK_DNS_VERSION="v1.13.1" && \
    cd ~/src && \
    git clone https://github.com/containers/aardvark-dns -b $AARDVARK_DNS_VERSION --depth 1 && \
    cd aardvark-dns && \
    make && \
    echo "changeme" | sudo -S make install && \
    git clean -d -x -f && \
    echo "changeme" | sudo -S rm -rf /tmp/*

# we build podman from source since the ubuntu repositories are often lagging behind
RUN export PODMAN_VERSION="v5.2.1" && \
    cd ~/src && \
    git clone https://github.com/containers/podman -b $PODMAN_VERSION --depth 1 && \
    cd podman && \
    export GOCACHE="$PWD/.gocache" && \
    make BUILDTAGS="apparmor cni exclude_graphdriver_devicemapper selinux seccomp systemd" && \
    make rootlessport && \
    echo "changeme" | sudo -S make install && \
    git clean -d -x -f && \
    podman --version && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    rm -rf ~/go

# configure tools required by podman
RUN echo "changeme" | sudo -S chmod u-s /usr/bin/new[gu]idmap && \
    echo "changeme" | sudo -S setcap cap_setuid+eip /usr/bin/newuidmap && \
    echo "changeme" | sudo -S setcap cap_setgid+eip /usr/bin/newgidmap

COPY --chown=root:root containers.conf registries.conf policy.json /etc/containers/

# enable the podman socket service so that other tools can use its docker-compatible API
RUN systemctl enable --user podman.socket && \
    systemctl enable --user podman.service

# build dive from source (using a fork that fixes the scrolling bug), see
# also here: https://github.com/wagoodman/dive/pull/520
RUN cd ~/src && \
    git clone https://github.com/pov1ba/dive.git -b fix/scrolling-contents && \
    cd dive && \
    export GOCACHE="$PWD/.gocache" && \
    make bootstrap && \
    echo "release: { prerelease: auto, draft: false }" > .goreleaser.yaml && \
    echo "builds: [{ binary: dive, env: [CGO_ENABLED=0], goos: [linux], goarch: [amd64], ldflags: '-s -w -X main.version={{.Version}} -X main.commit={{.Commit}} -X main.buildTime={{.Date}}' }]" >> .goreleaser.yaml && \
    make build && \
    mv snapshot/dive_linux_amd64_v1/dive ~/.local/bin/dive && \
    git clean -d -x -f && \
    ~/.local/bin/dive --version && \
    echo "changeme" | sudo -S rm -rf /tmp/* && \
    echo "changeme" | sudo -S rm -rf ~/go

# install tools for rust development
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal && \
    ~/.cargo/bin/rustup component add rustfmt && \
    ~/.cargo/bin/rustup component add clippy && \
    ~/.cargo/bin/rustup target add x86_64-unknown-linux-musl && \
    ~/.cargo/bin/rustup target add aarch64-unknown-linux-musl && \
    ~/.cargo/bin/rustup install nightly --profile minimal && \
    ~/.cargo/bin/rustup +nightly component add rustfmt && \
    ~/.cargo/bin/rustup +nightly component add clippy && \
    ~/.cargo/bin/cargo install just

# install tools for container development

## kubectl
RUN export KUBE_VERSION="v1.31.0" && \
    mkdir -p ~/.local/bin && \
    curl -LO "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl" && \
    curl -LO "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && rm kubectl.sha256 && \
    chmod +x kubectl && \
    mv ./kubectl ~/.local/bin/kubectl

## helm
RUN export HELM_VERSION="v3.15.4" && \
    mkdir -p ~/.local/bin && \
    curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" && \
    sha256sum --check helm*.sha256sum && rm helm*.sha256sum && \
    mkdir helm && \
    tar xzf helm*.tar.gz -C ./helm && \
    mv ./helm/linux-amd64/helm ~/.local/bin/helm && \
    rm helm*.tar.gz && \
    rm -rf helm && \
    ~/.local/bin/helm version

## kubetail
RUN cd ~/.oh-my-zsh/custom/plugins/ && \
    git clone https://github.com/johanhaleby/kubetail.git kubetail

## kubectx and kubens
RUN cd ~/.oh-my-zsh/custom/plugins/ && \
    git clone https://github.com/ahmetb/kubectx.git kubectx

## kubelogin
RUN export KUBELOGIN_VERSION="v0.1.4" && \
    export GOCACHE="/tmp/.gocache" && \
    mkdir -p ~/.local/bin && \
    curl -LO "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip" && \
    curl -LO "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip.sha256" && \
    cat kubelogin-linux-amd64.zip.sha256 | sha256sum --check && \
    rm kubelogin-linux-amd64.zip.sha256 && \
    unzip kubelogin-linux-amd64.zip -d ./kubelogin && \
    rm kubelogin-linux-amd64.zip && \
    chmod +x kubelogin/bin/linux_amd64/kubelogin && \
    mv ./kubelogin/bin/linux_amd64/kubelogin ~/.local/bin/kubelogin && \
    rm -rf ./kubelogin && \
    ~/.local/bin/kubelogin --version && \
    rm -rf $GOCACHE

## Cluster API
RUN export CLUSTER_API_VERSION="v1.8.1" && \
    mkdir -p ~/.local/bin && \
    curl -Lo clusterctl "https://github.com/kubernetes-sigs/cluster-api/releases/download/${CLUSTER_API_VERSION}/clusterctl-linux-amd64" && \
    chmod +x clusterctl && \
    mv ./clusterctl ~/.local/bin/clusterctl && \
    ~/.local/bin/clusterctl version

## cilium
RUN export CILIUM_CLI_VERSION="v0.16.15" && \
    export CLI_ARCH=amd64 && \
    mkdir -p ~/.local/bin && \
    curl -L --fail --remote-name-all "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}" && \
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum && \
    tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz ~/.local/bin && \
    rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} && \
    ~/.local/bin/cilium version --client

## hubble
RUN export HUBBLE_VERSION="v1.16.0" && \
    export HUBBLE_ARCH=amd64 && \
    mkdir -p ~/.local/bin && \
    curl -L --fail --remote-name-all "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}" && \
    sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum && \
    tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz ~/.local/bin && \
    rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum} && \
    ~/.local/bin/hubble --version

## kind
RUN export KIND_VERSION="v0.25.0" && \
    mkdir -p ~/.local/bin && \
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64" && \
    chmod +x ./kind && \
    mv ./kind ~/.local/bin/kind && \
    ~/.local/bin/kind --version

## kubebuilder
RUN export KUBEBUILDER_VERSION="v4.1.1" && \
    mkdir -p ~/.local/bin && \
    curl -L -o kubebuilder "https://github.com/kubernetes-sigs/kubebuilder/releases/download/${KUBEBUILDER_VERSION}/kubebuilder_linux_amd64" && \
    chmod +x ./kubebuilder && \
    mv ./kubebuilder ~/.local/bin/kubebuilder && \
    ~/.local/bin/kubebuilder version

## vault
RUN export VAULT_VERSION="1.17.3" && \
    mkdir -p ~/.local/bin && \
    curl -L -o vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" && \
    unzip vault.zip -d ./vault && \
    rm vault.zip && \
    chmod +x vault/vault && \
    mv ./vault/vault ~/.local/bin/vault && \
    rm -rf ./vault && \
    ~/.local/bin/vault --version

## kubeseal
RUN export KUBESEAL_VERSION="0.27.1" && \
    mkdir -p ~/.local/bin && \
    curl -L -o kubeseal.tar.gz "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz" && \
    tar -xvzf kubeseal.tar.gz kubeseal && \
    rm kubeseal.tar.gz && \
    chmod +x kubeseal && \
    mv ./kubeseal ~/.local/bin/kubeseal && \
    ~/.local/bin/kubeseal --version

## lazydocker
RUN export LAZYDOCKER_VERSION="0.23.3" && \
    mkdir -p ~/.local/bin && \
    curl -L -o lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" && \
    tar -xvzf lazydocker.tar.gz lazydocker && \
    rm lazydocker.tar.gz && \
    chmod +x lazydocker && \
    mv ./lazydocker ~/.local/bin/lazydocker && \
    ~/.local/bin/lazydocker --version

## minio CLI
RUN mkdir -p ~/.local/bin && \
    curl -LO https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && \
    mv mc ~/.local/bin/ && \
    ~/.local/bin/mc --version

COPY --chown=dev:dev \
    .zshrc \
    /home/dev/

COPY --chown=dev:dev .config/ /home/dev/.config/
COPY --chown=dev:dev .completions/ /home/dev/.completions/

## azure CLI completions
RUN curl -L -o ~/.completions/.zsh_completion_az https://raw.githubusercontent.com/Azure/azure-cli/dev/az.completion

# This image comes with a pre-configured powerlevel10k theme. You need to ensure that you have the NerdFont MesloLGF
# installed in your terminals for icons to be rendered correctly. If you want to configure your own options, just
# run "p10k configure" and step through the wizard. The default theme was created using the following options:
# - prompt style: lean
# - character set: unicode
# - prompt colors: 256 colors
# - current time: 12 hour format
# - prompt height: 2 lines
# - prompt connection: solid
# - prompt frame: no frame
# - prompt connection color: darkest
# - prompt spacing: sparse
# - icons: many icons
# - prompt flow: concise
# - transient prompt: no
# - instant prompt: verbose
#
# You may also want to enable additional plugins in ~/.p10k.zsh
