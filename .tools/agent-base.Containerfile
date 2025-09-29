FROM ubuntu:24.04

# Prevents interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        libssl-dev \
        neovim \
        pkg-config \
        rsync \
        software-properties-common \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Install just command runner
RUN curl -sSL https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# mirror host user
ARG USER_NAME
ARG USER_UID
ARG USER_GID

# Delete conflicting user/group if they exist, then add the correct ones
RUN set -eux; \
    # Remove any existing user with the same UID
    existing_user=$(getent passwd ${USER_UID} | cut -d: -f1 || true); \
    if [ -n "$existing_user" ]; then \
        deluser --remove-home "$existing_user"; \
    fi; \
    # Remove any existing group with the same GID
    existing_group=$(getent group ${USER_GID} | cut -d: -f1 || true); \
    if [ -n "$existing_group" ]; then \
        delgroup "$existing_group"; \
    fi; \
    # Create group and user
    addgroup --gid "$USER_GID" "$USER_NAME"; \
    adduser --uid "$USER_UID" --gid "$USER_GID" --disabled-password --gecos "" --shell /bin/sh "$USER_NAME"

WORKDIR /work
USER $USER_NAME
