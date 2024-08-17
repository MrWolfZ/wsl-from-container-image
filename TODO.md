# TODO

- pull tool installations and updates into a dedicated script that can be repeated after import to update tools
- use podman instead of docker to build the image
- split binary downloads into individual stages so that a base stage can be changed without having to re-download everything else
- update readme
  - mention that .wslconfig can be adjusted as required prior to import
  - mention how to configure WSL to run containers at boot
  - mention how to connect to podman inside WSL
