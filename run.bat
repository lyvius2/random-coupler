@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

set "REQUIRED_MAJOR=2"
set "REQUIRED_MINOR=6"
set "RUBY_INSTALLER_URL=https://rubyinstaller.org/downloads/"
set "SCRIPT_DIR=%~dp0"

echo ========================================
echo          Random Coupler Launcher
echo ========================================

:: ──────────────────────────────────────────
:: Ruby 설치 여부 확인
:: ──────────────────────────────────────────

where ruby >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Ruby was not found on this system.
    echo.
    echo  Please install Ruby %REQUIRED_MAJOR%.%REQUIRED_MINOR%.x manually:
    echo    1. Open your browser and go to: %RUBY_INSTALLER_URL%
    echo    2. Download the Ruby %REQUIRED_MAJOR%.%REQUIRED_MINOR%.x installer ^(WITH DevKit^)
    echo    3. Run the installer and follow the instructions
    echo    4. Re-run this script after installation
    echo.
    pause
    exit /b 1
)

:: ──────────────────────────────────────────
:: Ruby 버전 확인 (2.6.x 이상 권장)
:: ──────────────────────────────────────────

for /f "tokens=*" %%v in ('ruby -e "print RUBY_VERSION"') do set "RUBY_VERSION=%%v"
for /f "tokens=1,2 delims=." %%a in ("!RUBY_VERSION!") do (
    set "VER_MAJOR=%%a"
    set "VER_MINOR=%%b"
)

if "!VER_MAJOR!" == "%REQUIRED_MAJOR%" (
    if "!VER_MINOR!" == "%REQUIRED_MINOR%" (
        echo [INFO]  Ruby !RUBY_VERSION! detected.
        goto :run
    )
)

echo [WARN]  Ruby !RUBY_VERSION! detected, but %REQUIRED_MAJOR%.%REQUIRED_MINOR%.x is recommended.
echo         The program may still work, but compatibility is not guaranteed.
echo.
choice /c YN /m "Continue anyway?"
if errorlevel 2 (
    echo Aborted.
    exit /b 0
)

:: ──────────────────────────────────────────
:: coupler.rb 실행
:: ──────────────────────────────────────────

:run
echo [INFO]  Launching coupler.rb...
echo.
ruby "%SCRIPT_DIR%coupler.rb"

endlocal
