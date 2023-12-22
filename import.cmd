@echo off
wsl --import {{ name }} {{ name }} {{ name }}.tar
call :CHECK_FAIL
wsl -d {{ name }} sudo mv -f /etc/resolv.conf.overwrite /etc/resolv.conf
call :CHECK_FAIL
wsl -d {{ name }}

goto :EOF

:CHECK_FAIL
if NOT ["%errorlevel%"]==["0"] (
    pause
    exit %errorlevel%
)

