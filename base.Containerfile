ARG BASE_IMAGE
FROM ${BASE_IMAGE} as base-os

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
    # use the built-in unminimize mechanism
    yes | unminimize && \
    \
    # finally we can install various ubuntu packages to install all the default tools
    apt-get update && \
    apt-get install -y \
    ubuntu-minimal \
    ubuntu-server \
    ubuntu-standard \
    ubuntu-wsl \
    && \
    apt-get update && \
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

FROM base-os as base-with-tools

# install tools for C development (useful for building other projects from source)
RUN apt-get update && \
    apt-get install -y \
    autoconf \
    automake \
    build-essential \
    gcc \
    libncurses-dev \
    make \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install general tools
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    apt-utils \
    bash-completion \
    bzip2 \
    ca-certificates \
    gdb \
    gddrescue \
    gnupg \
    htop \
    lsb-release \
    pv \
    tree \
    uidmap \
    unzip \
    whois \
    zip \
    zsh \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

# install latest versions git from separate repo
RUN apt-add-repository ppa:git-core/ppa && \
    apt-get update && \
    apt-get install -y \
    git \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/* && \
    rm -rf /var/cache/swcatalog/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/command-not-found

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

# create some well-known directories
RUN mkdir /home/dev/.cache && \
    mkdir /home/dev/.config && \
    mkdir /home/dev/.config/systemd && \
    mkdir /home/dev/.config/zsh && \
    mkdir /home/dev/.config/zsh/completions && \
    mkdir /home/dev/.config/zsh/bash_completions && \
    mkdir /home/dev/.local && \
    mkdir /home/dev/.local/bin && \
    mkdir /home/dev/.local/share && \
    mkdir /home/dev/.ssh && \
    mkdir /home/dev/src && \
    chown -R dev:dev /home/dev

FROM base-os AS base-neovim

ARG NEOVIM_VERSION
RUN curl -fsSL "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux64.tar.gz" -o /tmp/nvim.tar.gz && \
    mkdir -p /tmp/nvim && \
    tar -xzf /tmp/nvim.tar.gz -C /tmp/nvim --strip-components=1 && \
    rm /tmp/nvim.tar.gz

FROM base-with-tools

COPY --from=base-neovim --chown=dev:dev /tmp/nvim /home/dev/.local
