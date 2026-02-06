@echo off
REM Desktop Automation Tool Launcher
REM This batch file launches the AutoHotkey script

echo ===============================================
echo   Desktop Automation Tool
echo   Starting...
echo ===============================================
echo.

REM Check if AutoHotkey v2 is installed
where AutoHotkey64.exe >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: AutoHotkey v2 not found!
    echo.
    echo ========================================
    echo   INSTALLATION OPTIONS
    echo ========================================
    echo.
    echo Option 1: Automatic Installation
    echo    Run: Install-AutoHotkey.ps1
    echo    (Right-click and "Run with PowerShell")
    echo.
    echo Option 2: Manual Download
    echo    Visit: https://www.autohotkey.com/
    echo    Download and install AutoHotkey v2
    echo.
    pause
    exit /b 1
)

REM Navigate to src directory and run main.ahk
cd /d "%~dp0src"

if exist "main.ahk" (
    echo Launching automation tool...
    echo.
    echo Hotkeys:
    echo   F3  - Capture coordinate
    echo   F1  - Start automation
    echo   F2  - Stop automation
    echo   ESC - Emergency stop
    echo.
    start "" "main.ahk"
    echo Tool launched successfully!
    timeout /t 3 >nul
) else (
    echo ERROR: main.ahk not found in src directory!
    echo Please ensure the project structure is intact.
    pause
    exit /b 1
)

exit /b 0
