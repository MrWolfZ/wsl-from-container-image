# Building a WSL distro from a container image

## Preconditions

- enable WSL2 and create a simple distro (e.g. `Ubuntu`)
- install [Docker](https://www.docker.com/get-started/) with WSL2 engine
- enable docker WSL integration for the distro created above
- install [just](https://github.com/casey/just) in WSL

## Building the distro

- create a file `passwd` and put a hashed password into it (e.g. `$6$some_salt$...`)
- create a file `.gitconfig` and configure it as desired
- create a file `resolv.conf` and configure your favorite nameserver (e.g. `nameserver 1.1.1.1` or `nameserver 8.8.8.8`)
- run `just build run` to build the image and run it as a container for testing
- run `just export` to export the image's file system to `C:\wsl`
- run the `C:\wsl\*-import.cmd` script to create the WSL distro
  - you will be prompted for the sudo password in order to fix the `resolv.conf`
