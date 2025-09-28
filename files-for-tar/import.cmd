@echo off
if exist .wslconfig.override (
  echo Creating .wslconfig using override...
  copy .wslconfig.override %USERPROFILE%\.wslconfig
) else (
  echo Creating .wslconfig using default...
  copy .wslconfig %USERPROFILE%\.wslconfig
)
call :CHECK_FAIL
echo Importing WSL distro @@ name @
wsl --import @@ name @ @@ name @ @@ name @.tar
call :CHECK_FAIL
echo Testing WSL distro...
wsl -d @@ name @ hostname
call :CHECK_FAIL
echo Configuring resolv.conf
powershell -C "(Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses | Select-String -NotMatch 'fec0' | ForEach-Object -Process { 'nameserver ' + $_.ToString() }) | Out-File -Encoding ASCII resolv.conf
call :CHECK_FAIL
wsl -d @@ name @ -u root bash -c "mv -f resolv.conf /etc/resolv.conf && sed -i 's/\r//' /etc/resolv.conf && chown root:root /etc/resolv.conf" > nul 2>&1
call :CHECK_FAIL
echo Configuring /etc/sysctl.conf
wsl -d @@ name @ -u root bash -c "echo 'fs.inotify.max_user_instances=8192' >> /etc/sysctl.conf && echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf && sysctl -p" > nul 2>&1
call :CHECK_FAIL
echo Fixing WSL interop...
wsl -d @@ name @ -u root /bin/bash -c "echo :WSLInterop:M::MZ::/init:PF > /usr/lib/binfmt.d/WSLInterop.conf" > nul 2>&1
wsl -d @@ name @ -u root systemctl restart systemd-binfmt > nul 2>&1
call :CHECK_FAIL
echo Generating SSH key
mkdir -p /mnt/c/Users/%USERNAME%/.ssh > nul 2>&1
wsl -d @@ name @ ssh-keygen -b 2048 -t rsa -f /mnt/c/Users/%USERNAME%/.ssh/id_rsa_@@ name @ -q -N "" > nul 2>&1
wsl -d @@ name @ mkdir -p ~/.ssh > nul 2>&1
wsl -d @@ name @ bash -c "cat /mnt/c/Users/%USERNAME%/.ssh/id_rsa_@@ name @.pub >> ~/.ssh/authorized_keys" > nul 2>&1
call :CHECK_FAIL
echo Run apt-get update...
wsl -d @@ name @ -u root apt-get update > nul 2>&1
call :CHECK_FAIL
echo Please configure a new password
wsl -d @@ name @ -u root passwd dev
call :CHECK_FAIL
wsl -d @@ name @ --cd ~

goto :EOF

:CHECK_FAIL
if NOT ["%errorlevel%"]==["0"] (
    pause
    exit %errorlevel%
)

