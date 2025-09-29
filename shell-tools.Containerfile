ARG BASE_IMAGE
ARG VARIANT_BASE_IMAGE

# Create a base stage with dev user for all tool download stages
FROM ${BASE_IMAGE} as base-with-dev-user

USER dev
SHELL ["/bin/bash", "-c"]
WORKDIR /home/dev

FROM base-with-dev-user as base-gitstatus

# this project is in maintenance mode, so we don't bother forcing to pass a version
# since this hardcoded version is likely the latest anyways
ARG GITSTATUS_VERSION="v1.5.4"
RUN curl -fLO "https://github.com/romkatv/gitstatus/releases/download/${GITSTATUS_VERSION}/gitstatusd-linux-x86_64.tar.gz" && \
    mkdir -p "$HOME/.cache/gitstatus" && \
    tar -C "$HOME/.cache/gitstatus" -xvf gitstatusd-linux-x86_64.tar.gz && \
    chmod +x "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64" && \
    rm gitstatusd-linux-x86_64.tar.gz && \
    rm -rf gitstatus

FROM base-with-dev-user as base-direnv

ARG DIRENV_VERSION
RUN curl -fLO "https://github.com/direnv/direnv/releases/download/${DIRENV_VERSION}/direnv.linux-amd64" && \
    mv direnv.linux-amd64 ~/.local/bin/direnv && \
    chmod +x ~/.local/bin/direnv

FROM base-with-dev-user as base-ripgrep

ARG RIPGREP_VERSION
RUN echo "changeme" | sudo -S mkdir -p /usr/local/share/man/man1/ && \
    curl -fLO "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
    curl -fLO "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz.sha256" && \
    sha256sum --check ripgrep*.sha256 && rm ripgrep*.sha256 && \
    mkdir ripgrep && \
    tar xzf ripgrep*.tar.gz -C ./ripgrep && \
    mv ./ripgrep/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg "$HOME/.local/bin/rg" && \
    mv ./ripgrep/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/complete/_rg "$HOME/.config/zsh/completions/" && \
    echo "changeme" | sudo -S mv ./ripgrep/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/doc/rg.1 /usr/local/share/man/man1/ && \
    rm ripgrep*.tar.gz && \
    rm -rf ripgrep

FROM base-with-dev-user as base-fzf

ARG FZF_VERSION
RUN curl -fLO "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" && \
    curl -fLO "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf_${FZF_VERSION}_checksums.txt" && \
    sha256sum --check --ignore-missing "fzf_${FZF_VERSION}_checksums.txt" && rm "fzf_${FZF_VERSION}_checksums.txt" && \
    mkdir fzf && \
    tar xzf fzf*.tar.gz -C ./fzf && \
    mv ./fzf/fzf "$HOME/.local/bin/fzf" && \
    rm fzf*.tar.gz && \
    rm -rf fzf && \
    "$HOME/.local/bin/fzf" --zsh > "$HOME/.config/zsh/fzf.zsh"

FROM base-with-dev-user as base-fd

ARG FD_VERSION
RUN echo "changeme" | sudo -S mkdir -p /usr/local/share/man/man1/ && \
    curl -fLO "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
    mkdir fd && \
    tar xzf fd*.tar.gz -C ./fd --strip-components=1 && \
    mv ./fd/fd "$HOME/.local/bin/fd" && \
    mv ./fd/autocomplete/_fd "$HOME/.config/zsh/completions/" && \
    echo "changeme" | sudo -S mv ./fd/fd.1 /usr/local/share/man/man1/ && \
    rm fd*.tar.gz && \
    rm -rf fd

FROM base-with-dev-user as base-zoxide

ARG ZOXIDE_VERSION
RUN echo "changeme" | sudo -S mkdir -p /usr/local/share/man/man1/ && \
    curl -fLO "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
    mkdir zoxide && \
    tar xzf zoxide*.tar.gz -C ./zoxide && \
    mv ./zoxide/zoxide "$HOME/.local/bin/zoxide" && \
    mv ./zoxide/completions/_zoxide "$HOME/.config/zsh/completions/" && \
    echo "changeme" | sudo -S mv ./zoxide/man/man1/ /usr/local/share/man/man1/ && \
    rm zoxide*.tar.gz && \
    rm -rf zoxide

FROM base-with-dev-user as base-eza

ARG EZA_VERSION
RUN echo "changeme" | sudo -S mkdir -p /usr/local/share/man/man1/ && \
    echo "changeme" | sudo -S mkdir -p /usr/local/share/man/man5/ && \
    curl -fLO "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz" && \
    mkdir eza && \
    tar xzf eza*.tar.gz -C ./eza && \
    rm eza*.tar.gz && \
    mv ./eza/eza "$HOME/.local/bin/" && \
    rm -rf eza && \
    curl -fLO "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/completions-${EZA_VERSION}.tar.gz" && \
    mkdir eza-completions && \
    tar xzf completions*.tar.gz -C ./eza-completions && \
    rm completions*.tar.gz && \
    mv ./eza-completions/target/completions-*/_eza "$HOME/.config/zsh/completions/" && \
    rm -rf eza-completions && \
    curl -fLO "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/man-${EZA_VERSION}.tar.gz" && \
    mkdir eza-man && \
    tar xzf man*.tar.gz -C ./eza-man && \
    rm man*.tar.gz && \
    echo "changeme" | sudo -S mv ./eza-man/target/man-*/*.1 /usr/local/share/man/man1/ && \
    echo "changeme" | sudo -S mv ./eza-man/target/man-*/*.5 /usr/local/share/man/man5/ && \
    rm -rf eza-man && \
    git clone --depth=1 https://github.com/eza-community/eza-themes.git "$HOME/.config/eza/eza-themes"

FROM base-with-dev-user as base-bat

ARG BAT_VERSION
RUN echo "changeme" | sudo -S mkdir -p /usr/local/share/man/man1/ && \
    curl -fLO "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
    mkdir bat && \
    tar xzf bat*.tar.gz -C ./bat && \
    mv ./bat/bat*/bat "$HOME/.local/bin/bat" && \
    mv ./bat/bat*/autocomplete/bat.zsh "$HOME/.config/zsh/completions/_bat" && \
    echo "changeme" | sudo -S mv ./bat/bat*/bat.1 /usr/local/share/man/man1/ && \
    rm bat*.tar.gz && \
    rm -rf bat

FROM base-with-dev-user as base-btop

ARG BTOP_VERSION
RUN curl -fLO "https://github.com/aristocratos/btop/releases/download/v${BTOP_VERSION}/btop-x86_64-linux-musl.tbz" && \
    mkdir btop && \
    tar xjf btop*.tbz -C ./btop && \
    rm btop*.tbz && \
    cd ./btop/btop && \
    \
    # the sed disables colored output
    PREFIX="$HOME/.local" make install | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' && \
    rm -rf btop

FROM base-with-dev-user as base-delta

ARG DELTA_VERSION
RUN curl -fLO "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
    mkdir delta && \
    tar xzf delta*.tar.gz -C ./delta && \
    mv ./delta/delta*/delta "$HOME/.local/bin/delta" && \
    rm delta*.tar.gz && \
    rm -rf delta

FROM base-with-dev-user as base-lazygit

ARG LAZYGIT_VERSION
RUN curl -fLO "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" && \
    mkdir lazygit && \
    tar xzf lazygit*.tar.gz -C ./lazygit && \
    mv ./lazygit/lazygit "$HOME/.local/bin/lazygit" && \
    rm lazygit*.tar.gz && \
    rm -rf lazygit

FROM base-with-dev-user as base-nano

ARG NANO_VERSION
RUN curl -fLO "https://www.nano-editor.org/dist/v${NANO_VERSION%%.*}/nano-${NANO_VERSION}.tar.xz" && \
    mkdir nano && \
    tar xf nano*.tar.xz -C ./nano && \
    cd nano/nano-* && \
    ./configure && \
    make && \
    make prefix="$HOME/.local" install && \
    cd ../.. && \
    rm nano*.tar.xz && \
    rm -rf nano

FROM base-with-dev-user as base-micro

ARG MICRO_VERSION
RUN curl -fLO "https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64.tar.gz" && \
    curl -fLO "https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64.tar.gz.sha" && \
    sha256sum --check micro*.sha && rm micro*.sha && \
    mkdir micro && \
    tar xzf micro*.tar.gz -C ./micro && \
    mv ./micro/micro-${MICRO_VERSION}/micro "$HOME/.local/bin/micro" && \
    rm micro*.tar.gz && \
    rm -rf micro

FROM base-with-dev-user as base-superfile

ARG SUPERFILE_VERSION
RUN curl -fLO "https://github.com/yorukot/superfile/releases/download/${SUPERFILE_VERSION}/superfile-linux-${SUPERFILE_VERSION}-amd64.tar.gz" && \
    mkdir superfile && \
    tar xzf superfile*.tar.gz -C ./superfile && \
    rm superfile*.tar.gz && \
    mv ./superfile/dist/superfile*/spf "$HOME/.local/bin/" && \
    rm -rf superfile

FROM base-with-dev-user as base-yazi

ARG YAZI_VERSION
RUN curl -fLO "https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/yazi-x86_64-unknown-linux-musl.zip" && \
    unzip yazi*.zip && \
    rm yazi*.zip && \
    mv yazi-x86_64-unknown-linux-musl/yazi "$HOME/.local/bin/" && \
    mv yazi-x86_64-unknown-linux-musl/ya "$HOME/.local/bin/" && \
    mv yazi-x86_64-unknown-linux-musl/completions/_yazi "$HOME/.config/zsh/completions/" && \
    mv yazi-x86_64-unknown-linux-musl/completions/_ya "$HOME/.config/zsh/completions/" && \
    rm -rf yazi-x86_64-unknown-linux-musl

FROM ${VARIANT_BASE_IMAGE}

# we make some directories owned by root for security
# reasons since processes running with the dev user's identity
# should not be able to modify these files maliciously
RUN echo "changeme" | sudo -S chown -R root:root /home/dev/.local/bin && \
    echo "changeme" | sudo -S chown -R root:root /home/dev/.config/systemd

COPY --from=base-gitstatus --chown=root:root /home/dev/.cache/gitstatus /home/dev/.cache/gitstatus
RUN "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64" --version

COPY --from=base-direnv --chown=root:root /home/dev/.local/bin/direnv /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" direnv --version

COPY --from=base-ripgrep --chown=root:root /home/dev/.local/bin/rg /home/dev/.local/bin/
COPY --from=base-ripgrep --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
COPY --from=base-ripgrep --chown=root:root /usr/local/share/man/man1/ /usr/local/share/man/man1/
RUN PATH="$HOME/.local/bin:$PATH" rg --version

COPY --from=base-fzf --chown=root:root /home/dev/.local/bin/fzf /home/dev/.local/bin/
COPY --from=base-fzf --chown=dev:dev /home/dev/.config/zsh/fzf.zsh /home/dev/.config/zsh/
RUN PATH="$HOME/.local/bin:$PATH" fzf --version

COPY --from=base-fd --chown=root:root /home/dev/.local/bin/fd /home/dev/.local/bin/
COPY --from=base-fd --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
COPY --from=base-fd --chown=root:root /usr/local/share/man/man1/ /usr/local/share/man/man1/
RUN PATH="$HOME/.local/bin:$PATH" fd --version

COPY --from=base-zoxide --chown=root:root /home/dev/.local/bin/zoxide /home/dev/.local/bin/
COPY --from=base-zoxide --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
COPY --from=base-zoxide --chown=root:root /usr/local/share/man/man1/ /usr/local/share/man/man1/
RUN PATH="$HOME/.local/bin:$PATH" zoxide --version

COPY --from=base-eza --chown=root:root /home/dev/.local/bin/eza /home/dev/.local/bin/
COPY --from=base-eza --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
COPY --from=base-eza --chown=dev:dev /home/dev/.config/eza /home/dev/.config/eza
COPY --from=base-eza --chown=root:root /usr/local/share/man/man1/ /usr/local/share/man/man1/
COPY --from=base-eza --chown=root:root /usr/local/share/man/man5/ /usr/local/share/man/man5/
RUN PATH="$HOME/.local/bin:$PATH" eza --version

COPY --from=base-bat --chown=root:root /home/dev/.local/bin/bat /home/dev/.local/bin/
COPY --from=base-bat --chown=root:root /home/dev/.config/zsh/completions/* /home/dev/.config/zsh/completions/
COPY --from=base-bat --chown=root:root /usr/local/share/man/man1/ /usr/local/share/man/man1/
RUN PATH="$HOME/.local/bin:$PATH" bat --version

COPY --from=base-btop --chown=root:root /home/dev/.local/bin/btop /home/dev/.local/bin/
COPY --from=base-btop --chown=dev:dev /home/dev/.local/share/btop /home/dev/.local/share/btop
RUN PATH="$HOME/.local/bin:$PATH" btop --version

COPY --from=base-delta --chown=root:root /home/dev/.local/bin/delta /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" delta --version

COPY --from=base-lazygit --chown=root:root /home/dev/.local/bin/lazygit /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" lazygit --version

COPY --from=base-nano --chown=root:root /home/dev/.local/bin/nano /home/dev/.local/bin/
COPY --from=base-nano --chown=dev:dev /home/dev/.local/share/nano /home/dev/.local/share/nano
COPY --from=base-nano --chown=dev:dev /home/dev/.local/share/doc/nano /home/dev/.local/share/doc/nano
COPY --from=base-nano --chown=dev:dev /home/dev/.local/share/locale /home/dev/.local/share/locale
COPY --from=base-nano --chown=dev:dev /home/dev/.local/share/info /home/dev/.local/share/info
COPY --from=base-nano --chown=dev:dev /home/dev/.local/share/man /home/dev/.local/share/man
RUN PATH="$HOME/.local/bin:$PATH" nano --version

COPY --from=base-micro --chown=root:root /home/dev/.local/bin/micro /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" micro --version

COPY --from=base-superfile --chown=root:root /home/dev/.local/bin/spf /home/dev/.local/bin/
RUN PATH="$HOME/.local/bin:$PATH" spf --version

COPY --from=base-yazi --chown=root:root /home/dev/.local/bin/yazi /home/dev/.local/bin/
COPY --from=base-yazi --chown=root:root /home/dev/.local/bin/ya /home/dev/.local/bin/
COPY --from=base-yazi --chown=root:root /home/dev/.config/zsh/completions/_yazi /home/dev/.config/zsh/completions/
COPY --from=base-yazi --chown=root:root /home/dev/.config/zsh/completions/_ya /home/dev/.config/zsh/completions/
RUN PATH="$HOME/.local/bin:$PATH" yazi --version
