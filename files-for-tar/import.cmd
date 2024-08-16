@echo off
echo Creating .wslconfig...
copy .wslconfig %USERPROFILE%\.wslconfig
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
wsl -d @@ name @ -u root mv -f resolv.conf /etc/resolv.conf > nul 2>&1
call :CHECK_FAIL
wsl -d @@ name @ -u root sed -i 's/\r//' /etc/resolv.conf > nul 2>&1
call :CHECK_FAIL
wsl -d @@ name @ -u root chown root:root /etc/resolv.conf > nul 2>&1
call :CHECK_FAIL
echo Configuring .gitconfig
wsl -d @@ name @ sed -i "s#git-credential-manager.exe#$(find /mnt/c/Users/*/AppData/Local/Programs/Git/mingw64/libexec/git-core/git-credential-manager.exe -type f)#" ~/.config/git/config > nul 2>&1
call :CHECK_FAIL
echo Fixing WSL interop...
wsl -d @@ name @ -u root /bin/bash -c "echo :WSLInterop:M::MZ::/init:PF > /usr/lib/binfmt.d/WSLInterop.conf" > nul 2>&1
wsl -d @@ name @ -u root systemctl restart systemd-binfmt > nul 2>&1
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

