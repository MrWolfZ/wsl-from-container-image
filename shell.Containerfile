ARG SHELL_TOOLS_IMAGE

FROM ${SHELL_TOOLS_IMAGE}

COPY --chown=dev:dev .config/zsh/.zsh_plugins.txt /home/dev/.config/zsh/

RUN git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.config/zsh/.antidote" && \
    export ZDOTDIR="$HOME/.config/zsh" && \
    zsh -c 'source "$HOME/.config/zsh/.antidote/antidote.zsh" && antidote load'

# Copy shell configuration files
COPY --chown=dev:dev .zshenv .bashrc_additions /home/dev/
COPY --chown=dev:dev .config/ /home/dev/.config/

RUN echo 'source "$HOME/.bashrc_additions"' >> "$HOME/.bashrc"

# let's make our zsh profile readonly to prevent accidental modification by other tools;
# an extra layer of security would be to also make the files owned by `root` instead of the
# dev user, but that seems like overkill
RUN chmod 444 /home/dev/.config/zsh/.zshrc

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
#
# Alternatively you may want to use a different prompt like Starship (https://starship.rs),
# which offers simpler configuration.
