# Building a WSL distro from a container image

## Preconditions

- enable WSL2 and create a simple distro (e.g. `Ubuntu`)
- install [Docker](https://www.docker.com/get-started/) with WSL2 engine
- enable docker WSL integration for the distro created above
- install [just](https://github.com/casey/just) in WSL
- install [recommended font](https://github.com/romkatv/powerlevel10k/blob/master/font.md) on host

## Building the distro

- adjust `.gitconfig` as desired
- run `just build run` to build the image and run it as a container for testing
- run `just export` to export the image's file system to `C:\wsl`
- run the `C:\wsl\*-import.cmd` script to create the WSL distro
  - you will be prompted for the sudo password in order to fix the `resolv.conf`
