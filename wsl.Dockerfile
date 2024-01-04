FROM ubuntu:22.04
ARG TIMEZONE=Europe/Zurich

# create an initial fully upgraded ubuntu installation
RUN export DEBIAN_FRONTEND=noninteractive && \
    \
    # the ubuntu images come minimized, so let's revert that to get a full-fledged environment
    yes | unminimize && \
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
    apt-get upgrade -y

# configure additional OS settings
RUN export DEBIAN_FRONTEND=noninteractive && \
    locale-gen "en_US" && \
    locale-gen "en_US.UTF-8" && \
    dpkg-reconfigure locales && \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

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
    unzip \
    zsh

# install tools for C development (useful for bulding other projects from source)
RUN apt-get update && \
    apt-get install -y \
    gcc \
    git \
    libc6-dev \
    libglib2.0-dev \
    libglib2.0-dev \
    libseccomp-dev \
    libseccomp-dev \
    libsystemd-dev \
    make \
    pkg-config \
    runc

# install tools for container development; we use the kubic project for installing podman and buildah
# (as described here: https://podman.io/docs/installation#debian) since the versions in the official
# ubuntu repositories are horribly outdated
COPY containers-apt-preferences.txt /etc/apt/preferences.d/containers
RUN mkdir -p /etc/apt/keyrings && \
    # install Debian Unstable/Sid repository
    curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/Debian_Unstable/Release.key \
    | gpg --dearmor \
    | sudo tee /etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg > /dev/null && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg]\
    https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/Debian_Unstable/ /" \
    | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list > /dev/null && \
    # finally, install the tools
    apt-get update && \
    apt-get install -y \
    containernetworking-plugins \
    buildah \
    podman && \
    export DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
    curl -OL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb && \
    apt install ./dive_${DIVE_VERSION}_linux_amd64.deb && \
    rm ./dive_${DIVE_VERSION}_linux_amd64.deb

# enable the podman socket service so that other tools can use its docker-compatible API
RUN systemctl enable --user podman.socket

# install tools for Azure development
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# install tools for dotnet development
COPY dotnet-apt-preferences.txt /etc/apt/preferences.d/dotnet
RUN wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -r -s)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y \
    dotnet-sdk-6.0 \
    dotnet-sdk-7.0 \
    dotnet-sdk-8.0

# install tools for java development
RUN apt-get update && \
    apt-get install -y \
    openjdk-11-jdk \
    openjdk-17-jdk

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
    qemu-user-static

# install tools for python development
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
    python3 \
    python3-venv \
    python3.12 \
    python3.12-venv

# run one last upgrade to ensure everything is up to date
RUN apt-get update && apt-get upgrade -y

COPY wsl.conf.copy /etc/wsl.conf

# create a dedicated user
RUN --mount=type=secret,id=dev_passwd \
    groupadd dev --gid 1000 && \
    useradd dev \
    --uid 1000 \
    --gid 1000 \
    --password $(cat /run/secrets/dev_passwd) \
    --shell $(which zsh) \
    --create-home && \
    usermod -aG sudo dev

# run the rest of the setup as the dev user
USER dev
SHELL ["/bin/bash", "-c"]
WORKDIR /home/dev

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
ARG NVM_VERSION=v0.39.7
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash && \
    source .nvm/nvm.sh && \
    nvm install stable && \
    nvm install --lts

# install tools for go development (rename go dir to golang to work around `make` issue when a `go` dir is in path)
ARG GO_VERSION=1.21.5
RUN mkdir -p ~/.local/bin && \
    curl -OL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C ~/.local/bin -xvf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz && \
    mv ~/.local/bin/go ~/.local/bin/golang

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
RUN mkdir -p ~/.local/bin && \
    export KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl" && \
    curl -LO "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && rm kubectl.sha256 && \
    chmod +x kubectl && \
    mv ./kubectl ~/.local/bin/kubectl

## helm
RUN mkdir -p ~/.local/bin && \
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    HELM_INSTALL_DIR=~/.local/bin PATH=$PATH:~/.local/bin ./get_helm.sh --no-sudo && \
    rm -f get_helm.sh

## kubetail
RUN cd ~/.oh-my-zsh/custom/plugins/ && \
    git clone https://github.com/johanhaleby/kubetail.git kubetail

## kubectx and kubens
RUN cd ~/.oh-my-zsh/custom/plugins/ && \
    git clone https://github.com/ahmetb/kubectx.git kubectx

## kubelogin
ARG KUBELOGIN_VERSION="v0.0.34"
RUN mkdir -p ~/.local/bin && \
    curl -LO "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip" && \
    curl -LO "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip.sha256" && \
    cat kubelogin-linux-amd64.zip.sha256 | sha256sum --check && \
    rm kubelogin-linux-amd64.zip.sha256 && \
    unzip kubelogin-linux-amd64.zip -d ./kubelogin && \
    rm kubelogin-linux-amd64.zip && \
    chmod +x kubelogin/bin/linux_amd64/kubelogin && \
    mv ./kubelogin/bin/linux_amd64/kubelogin ~/.local/bin/kubelogin && \
    rm -rf ./kubelogin && \
    ~/.local/bin/kubelogin --version

## Cluster API
ARG CLUSTER_API_VERSION="v1.5.3"
RUN mkdir -p ~/.local/bin && \
    curl -Lo clusterctl "https://github.com/kubernetes-sigs/cluster-api/releases/download/${CLUSTER_API_VERSION}/clusterctl-linux-amd64" && \
    chmod +x clusterctl && \
    mv ./clusterctl ~/.local/bin/clusterctl && \
    ~/.local/bin/clusterctl version

## cilium
RUN mkdir -p ~/.local/bin && \
    export CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) && \
    export CLI_ARCH=amd64 && \
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} && \
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum && \
    tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz ~/.local/bin && \
    rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} && \
    ~/.local/bin/cilium version --client

## hubble
RUN mkdir -p ~/.local/bin && \
    export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt) && \
    export HUBBLE_ARCH=amd64 && \
    curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum} && \
    sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum && \
    tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz ~/.local/bin && \
    rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum} && \
    ~/.local/bin/hubble --version

## kind
ARG KIND_VERSION="v0.20.0"
RUN mkdir -p ~/.local/bin && \
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64 && \
    chmod +x ./kind && \
    mv ./kind ~/.local/bin/kind && \
    ~/.local/bin/kind --version

## kubebuilder
RUN mkdir -p ~/.local/bin && \
    curl -L -o kubebuilder https://go.kubebuilder.io/dl/latest/$(~/.local/bin/golang/bin/go env GOOS)/$(~/.local/bin/golang/bin/go env GOARCH) && \
    chmod +x ./kubebuilder && \
    mv ./kubebuilder ~/.local/bin/kubebuilder && \
    ~/.local/bin/kubebuilder version

## vault
ARG VAULT_VERSION=1.15.4
RUN mkdir -p ~/.local/bin && \
    curl -L -o vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
    unzip vault.zip -d ./vault && \
    rm vault.zip && \
    chmod +x vault/vault && \
    mv ./vault/vault ~/.local/bin/vault && \
    rm -rf ./vault && \
    ~/.local/bin/vault --version

## kubeseal
ARG KUBESEAL_VERSION=0.24.4
RUN mkdir -p ~/.local/bin && \
    curl -L -o kubeseal.tar.gz https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz && \
    tar -xvzf kubeseal.tar.gz kubeseal && \
    rm kubeseal.tar.gz && \
    chmod +x kubeseal && \
    mv ./kubeseal ~/.local/bin/kubeseal && \
    ~/.local/bin/kubeseal --version

## lazydocker
ARG LAZYDOCKER_VERSION=0.23.1
RUN mkdir -p ~/.local/bin && \
    curl -L -o lazydocker.tar.gz https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz && \
    tar -xvzf lazydocker.tar.gz lazydocker && \
    rm lazydocker.tar.gz && \
    chmod +x lazydocker && \
    mv ./lazydocker ~/.local/bin/lazydocker && \
    ~/.local/bin/lazydocker --version

RUN mkdir -p ~/.local/bin && \
    curl -LO https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && \
    mv mc ~/.local/bin/ && \
    ~/.local/bin/mc --version

# docker mounts the /etc/resolv.conf, and we cannot overwrite it for the export; therefore
# we copy the file to a temporary location and then move it during the WSL import
COPY --chown=root:root resolv.conf /etc/resolv.conf.overwrite

COPY --chown=dev:dev \
    .zshrc \
    .p10k.zsh \
    .gitconfig \
    .zsh_completion_just \
    .zsh_completion_kubectx \
    .zsh_completion_kubetail \
    /home/dev/

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
