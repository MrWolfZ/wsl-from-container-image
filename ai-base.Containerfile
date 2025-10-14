ARG DEV_BASE_IMAGE
ARG WSL_BASE_IMAGE

FROM ${DEV_BASE_IMAGE} as dev-base

FROM ${WSL_BASE_IMAGE} as base

# install dependencies for container tools
RUN apt-get update && \
    apt-get install -y \
    iptables \
    libdevmapper-dev \
    libseccomp-dev \
    libselinux1-dev \
    libslirp-dev \
    libsystemd-dev \
    libyajl-dev \
    passt \
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

FROM base as base-container-tools

# copy container tools so that we can run containers
COPY --from=dev-base /opt/cni/bin /opt/cni/bin

COPY --from=dev-base /home/dev/.local/bin/slirp4netns /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" slirp4netns --version

COPY --from=dev-base /home/dev/.local/bin/conmon /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" conmon --version

COPY --from=dev-base /home/dev/.local/libexec/podman /home/dev/.local/libexec/podman
RUN PATH="$HOME/.local/libexec/podman:$PATH" netavark --version
RUN PATH="$HOME/.local/libexec/podman:$PATH" aardvark-dns --version

COPY --from=dev-base /home/dev/.local/bin/crun /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" crun --version

COPY --from=dev-base /home/dev/.local/bin/lazydocker /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" lazydocker --version

COPY --from=dev-base /home/dev/.local/bin/podman* /home/dev/.local/bin/
COPY --from=dev-base /home/dev/.local/share/systemd/user/ /home/dev/.local/share/systemd/user/
COPY --from=dev-base /home/dev/.local/share/man/man1/ /home/dev/.local/share/man/man1/
COPY --from=dev-base /home/dev/.local/share/man/man5/ /home/dev/.local/share/man/man5/
COPY --from=dev-base /home/dev/.local/share/man/man7/ /home/dev/.local/share/man/man7/
COPY --from=dev-base /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" podman --version && PATH="$HOME/.local/bin:$PATH" podman-remote --version

# configure tools required by podman
RUN echo "changeme" | sudo -S chmod u-s /usr/bin/new[gu]idmap && \
    echo "changeme" | sudo -S setcap cap_setuid+eip /usr/bin/newuidmap && \
    echo "changeme" | sudo -S setcap cap_setgid+eip /usr/bin/newgidmap

COPY --chown=root:root containers.conf registries.conf policy.json /home/dev/.config/containers/

# enable the podman socket service so that other tools can use its docker-compatible API
RUN systemctl enable --user podman.socket && \
    systemctl enable --user podman.service

# create systemd drop-in to set PATH for podman services so they can find helper binaries
RUN mkdir -p "$HOME/.config/systemd/user/podman.service.d" && \
    printf '[Service]\nEnvironment="PATH=/home/dev/.local/bin:/home/dev/.local/libexec/podman:/usr/local/bin:/usr/bin:/bin"\n' > "$HOME/.config/systemd/user/podman.service.d/path.conf" && \
    mkdir -p "$HOME/.config/systemd/user/podman.socket.d" && \
    printf '[Service]\nEnvironment="PATH=/home/dev/.local/bin:/home/dev/.local/libexec/podman:/usr/local/bin:/usr/bin:/bin"\n' > "$HOME/.config/systemd/user/podman.socket.d/path.conf"

FROM base-container-tools

USER root

# see https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
ARG NVIDIA_CONTAINER_TOOLKIT_VERSION
RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
    apt-get update && \
    apt-get install -y \
      nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

USER dev

RUN echo -e '#!/usr/bin/env bash\n\nset -e\n\n' > ai-init.sh && \
    echo 'sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml' >> ai-init.sh && \
    echo 'nvidia-ctk cdi list' >> ai-init.sh && \
    echo 'podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable ubuntu nvidia-smi -L' >> ai-init.sh && \
    chmod +x ai-init.sh
