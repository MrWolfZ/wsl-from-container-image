# Building a WSL distro from a container image

## Preconditions

- enable WSL2 and create a simple distro (e.g. `Ubuntu`)
- install [Docker](https://www.docker.com/get-started/) with WSL2 engine
- enable docker WSL integration for the distro created above
- install [just](https://github.com/casey/just) in WSL
- install [recommended font](https://github.com/romkatv/powerlevel10k/blob/master/font.md) on host

## Building the distro

- run `just build-image <variant>` to build the image
- run `just run <variant>` to run the image as a container for testing
- run `just export <variant>` to export the image's file system
- run the `<distro>-import.cmd` script to create the WSL distro
