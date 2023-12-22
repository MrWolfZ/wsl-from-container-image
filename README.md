# Building a WSL distro from a container image

- create a file `passwd` and put a hash password into it
- create a file `.gitconfig` and configure it as desired
- create a file `resolv.conf` and configure your favorite nameserver (e.g. 1.1.1.1 or 8.8.8.8)
- run `just build run` to build the image and run it as a container for testing
- run `just export` to export the image's file system to `C:\wsl`
- run the `C:\wsl\*-import.cmd` script to create the WSL distro
