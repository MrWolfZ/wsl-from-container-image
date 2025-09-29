ARG WSL_BASE_IMAGE
FROM ${WSL_BASE_IMAGE}

COPY wsl.conf /etc/wsl.conf

# run the rest of the setup as the dev user
USER dev
SHELL ["/bin/bash", "-c"]
WORKDIR /home/dev
