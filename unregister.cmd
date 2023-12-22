@echo off
wsl --unregister {{ name }}
call :CHECK_FAIL
rmdir /S /Q {{ name }}
call :CHECK_FAIL

goto :EOF

:CHECK_FAIL
if NOT ["%errorlevel%"]==["0"] (
    pause
    exit %errorlevel%
)
