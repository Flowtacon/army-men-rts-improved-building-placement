@echo off
setlocal
title Army Men RTS - Improved Building Placement - Uninstall

echo.
echo Army Men RTS - Improved Building Placement
echo ===========================================
echo Uninstalling the mod...
echo.

set "PowerShellExe=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "ScriptPath=%~dp0uninstall.ps1"
set "ExitCode=1"

if not exist "%PowerShellExe%" (
    echo ERROR: Windows PowerShell was not found.
    set "ExitCode=2"
    goto Finish
)

if not exist "%ScriptPath%" (
    echo ERROR: uninstall.ps1 is missing.
    echo Extract all release files into the same directory and try again.
    set "ExitCode=2"
    goto Finish
)

"%PowerShellExe%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%ScriptPath%"
set "ExitCode=%ERRORLEVEL%"

:Finish
echo.
if "%ExitCode%"=="0" (
    echo Finished successfully. You can close this window.
) else (
    echo Uninstallation failed. Read the error message above.
    echo If access was denied, right-click this file and choose Run as administrator.
)
echo.

if /I not "%~1"=="--no-pause" pause
exit /b %ExitCode%
