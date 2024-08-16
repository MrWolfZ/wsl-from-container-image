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

  sed 's/@@ name @/{{ replace(name, ".", "-") }}/g' files-for-image/wsl.conf > files-for-image/wsl.conf.copy

  docker build files-for-image -f wsl.Containerfile --tag {{ img }}

  rm files-for-image/wsl.conf.copy

run:
  docker run -it --rm --name {{ name }} {{ img }} zsh

export:
  docker rm -f {{ name }} > /dev/null 2>&1
  docker run --name {{ name }} -d {{ img }} sleep infinity
  docker export {{ name }} -o .build/{{ name }}.tar
  docker stop {{ name }} -t 1
  docker rm {{ name }}

package:
  cd .build && tar cf - ./ -P | pv -s $(du -sb .build/ | awk '{print $1}') | gzip > wsl-{{ name }}.tar.gz

install:
  mkdir -p /mnt/c/wsl
  rm -f /mnt/c/wsl/{{ name }}.tar
  rm -f /mnt/c/wsl/{{ name }}*.cmd
  rsync -ah --progress .build/* /mnt/c/wsl/

install-package:
  mkdir -p /mnt/c/wsl
  rm -f /mnt/c/wsl/wsl-{{ name }}.tar.gz
  mv .build/wsl-{{ name }}.tar.gz /mnt/c/wsl/

backup:
  mkdir -p /mnt/c/wsl
  rm -f /mnt/c/wsl/src-backup.tar.gz
  tar czf /mnt/c/wsl/src-backup.tar.gz \
    --exclude venv \
    --exclude .azure \
    --exclude .build \
    --exclude build \
    --exclude bin \
    --exclude obj \
    --exclude .tmp \
    --exclude tmp \
    --exclude target \
    ~/src
  cp /mnt/c/wsl/src-backup.tar.gz /mnt/c/wsl/src-backup-$(date +%Y-%m-%d).tar.gz

restore:
  cp /mnt/c/wsl/src-backup.tar.gz ~/
  tar xzf ~/src-backup.tar.gz ~/src
  rm ~/src-backup.tar.gz
