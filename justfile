name := "ubuntu-22.04"
img := "wsl:" + name

build:
  sed 's/{{{{ name }}/{{ name }}/g' wsl.conf > wsl.conf.copy
  docker build . -f wsl.Dockerfile --tag {{ img }} --secret id=dev_passwd,src=./passwd
  rm wsl.conf.copy

run:
  docker run -it --rm --name {{ name }} {{ img }} zsh

export:
  mkdir -p /mnt/c/wsl
  rm -f /mnt/c/wsl/{{ name }}.tar
  docker run --name {{ name }} -d {{ img }} sleep infinity
  docker export {{ name }} -o /mnt/c/wsl/{{ name }}.tar
  docker stop {{ name }}
  docker rm {{ name }}
  sed 's/{{{{ name }}/{{ name }}/g' import.cmd > /mnt/c/wsl/{{ name }}-import.cmd
  sed 's/{{{{ name }}/{{ name }}/g' unregister.cmd > /mnt/c/wsl/{{ name }}-unregister.cmd
