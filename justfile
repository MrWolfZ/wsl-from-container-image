name := "ubuntu-24.04"
img := "wsl:" + name

container_tool := "docker"

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

  {{ container_tool }} build files-for-image -f wsl.Containerfile --tag {{ img }}

  rm files-for-image/wsl.conf.copy

run:
  {{ container_tool }} run -it --rm --name {{ name }} {{ img }} zsh

export:
  {{ container_tool }} rm -f {{ name }} > /dev/null 2>&1
  {{ container_tool }} run --name {{ name }} -d {{ img }} sleep infinity
  {{ container_tool }} export {{ name }} -o .build/{{ name }}.tar
  {{ container_tool }} stop {{ name }} -t 1
  {{ container_tool }} rm {{ name }}

package:
  cd .build && tar cf - ./ -P | pv -s $(du -sb .build/ | awk '{print $1}') | gzip > wsl-{{ name }}.tar.gz

install:
  mkdir -p /mnt/c/wsl
  rm -f /mnt/c/wsl/{{ name }}.tar
  rm -f /mnt/c/wsl/{{ name }}*.cmd
  rsync -ah --info=progress2 .build/ /mnt/c/wsl/

install-package:
  mkdir -p /mnt/c/wsl
  rm -f /mnt/c/wsl/wsl-{{ name }}.tar.gz
  mv .build/wsl-{{ name }}.tar.gz /mnt/c/wsl/

backup:
  rm ~/backup.tar
  cd ~ && tar cf backup.tar \
    --exclude venv \
    --exclude .azure \
    --exclude .build \
    --exclude build \
    --exclude bin \
    --exclude obj \
    --exclude .tmp \
    --exclude tmp \
    --exclude target \
    --exclude node_modules \
    src

  cd ~ && tar rf backup.tar \
    .completions \
    .config \
    .p10k.zsh \
    .zsh_history \
    .zshrc

  mkdir -p /mnt/c/wsl
  rm -f /mnt/c/wsl/backup.tar
  cp ~/backup.tar ~/backup-$(date +%Y-%m-%d).tar
  mv ~/backup*.tar /mnt/c/wsl/

restore:
  cp /mnt/c/wsl/backup.tar ~/
  tar xf ~/backup.tar -C ~/
  rm ~/backup.tar
