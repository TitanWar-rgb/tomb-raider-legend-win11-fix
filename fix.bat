@echo off
setlocal
echo [Tomb Raider: Legend - Windows 11 Startup Crash Fix]
echo.

if not exist "trl.exe" (
    echo ERROR: trl.exe was not found.
    echo Please place this file directly inside your Tomb Raider Legend game folder.
    echo.
    pause
    exit /b 1
)

if exist "nvidia.bik" (
    if not exist "_backup_original" mkdir "_backup_original"
    echo Creating backup of original nvidia.bik...
    copy "nvidia.bik" "_backup_original\nvidia.bik" >nul
    echo Disabling nvidia.bik...
    ren "nvidia.bik" "nvidia.bik.disabled"
    echo.
    echo SUCCESS: Fix applied. You can now launch the game normally.
) else (
    if exist "nvidia.bik.disabled" (
        echo The fix is already applied (nvidia.bik.disabled is present).
    ) else (
        echo nvidia.bik was not found.
    )
)

echo.
pause
