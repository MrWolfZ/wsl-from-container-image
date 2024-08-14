@echo off
echo Creating .wslconfig...
copy .wslconfig %USERPROFILE%\.wslconfig
call :CHECK_FAIL
echo Importing WSL distro @@ name @
wsl --import @@ name @ @@ name @ @@ name @.tar
call :CHECK_FAIL
echo Testing WSL distro...
wsl -d @@ name @ /bin/bash -c "hostname"
call :CHECK_FAIL
echo Configuring resolv.conf
powershell -C "(Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses | Select-String -NotMatch 'fec0' | ForEach-Oject -Process { 'nameserver ' + $_.ToString() }) | Out-File -Encoding ASCII resolv.conf
call :CHECK_FAIL
wsl -d @@ name @ -u root mv -f resolv.conf /etc/resolv.conf > /dev/null 2>&1
call :CHECK_FAIL
wsl -d @@ name @ -u root sed -i 's/\r//' /etc/resolv.conf
call :CHECK_FAIL
wsl -d @@ name @ -u root chown root:root /etc/resolv.conf > /dev/null 2>&1
call :CHECK_FAIL
echo Configuring .gitconfig
wsl -d @@ name @ mkdir -p ~/.config/git > /dev/null 2>&1
wsl -d @@ name @ cp .gitconfig ~/.config/git/config > /dev/null 2>&1
call :CHECK_FAIL
echo Fixing WSL interop...
wsl -d @@ name @ -u root echo :WSLInterop:M::MZ::/init:PF > /usr/lib/binfmt.d/WSLInterop.conf > /dev/null 2>&1
wsl -d @@ name @ -u root systemctl restart systemd-binfmt > /dev/null 2>&1
call :CHECK_FAIL
echo Please configure a new password (the current one is 'changeme'):
wsl -d @@ name @ passwd
call :CHECK_FAIL
wsl -d @@ name @ --cd ~

goto :EOF

:CHECK_FAIL
if NOT ["%errorlevel%"]==["0"] (
    pause
    exit %errorlevel%
)

