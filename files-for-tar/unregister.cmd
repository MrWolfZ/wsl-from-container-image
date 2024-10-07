@echo off
echo You are about to unregister distro @@ name @, are you sure?
pause

wsl --unregister @@ name @
call :CHECK_FAIL
rmdir /S /Q @@ name @
call :CHECK_FAIL

goto :EOF

:CHECK_FAIL
if NOT ["%errorlevel%"]==["0"] (
    pause
    exit %errorlevel%
)
