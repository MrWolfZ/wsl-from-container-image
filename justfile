name := "ubuntu-24.04"
img := "wsl:" + name

default:
  just --list --unsorted

build:
  rm -rf .build && mkdir .build

  # copy recursive including hidden files
  rsync -avx files-for-tar/ .build/

  sed -i 's/@@ name @/{{ name }}/g' .build/import.cmd
  mv .build/import.cmd .build/{{ name }}-import.cmd

  sed -i 's/@@ name @/{{ name }}/g' .build/unregister.cmd
  mv .build/unregister.cmd .build/{{ name }}-unregister.cmd

  sed 's/@@ name @/{{ name }}/g' files-for-image/wsl.conf > files-for-image/wsl.conf.copy

  docker build files-for-image -f wsl.Dockerfile --tag {{ img }}

  rm files-for-image/wsl.conf.copy

run:
  docker run -it --rm --name {{ name }} {{ img }} zsh

export:
  docker run --replace --name {{ name }} -d {{ img }} sleep infinity
  docker export {{ name }} -o .build/{{ name }}.tar
  docker stop {{ name }} -t 1
  docker rm {{ name }}

package:
  tar czf wsl-{{ name }}.tar.gz -C .build/ .
  rm -rf .build

move-win:
  mkdir -p /mnt/c/wsl
  rm -f /mnt/c/wsl/wsl-{{ name }}.tar.gz
  mv wsl-{{ name }}.tar.gz /mnt/c/wsl/

backup:
  tar czf /mnt/c/wsl/src-backup.tar.gz --exclude venv --exclude .azure ~/src
  cp /mnt/c/wsl/src-backup.tar.gz /mnt/c/wsl/src-backup-$(date +%Y-%m-%d).tar.gz

restore:
  cp /wsl/src-backup.tar.gz ~/
  tar xzf src-backup.tar.gz ~/src
  rm ~/src-backup.tar.gz
