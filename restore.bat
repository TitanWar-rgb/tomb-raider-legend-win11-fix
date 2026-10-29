@echo off
setlocal
echo [Tomb Raider: Legend - Restore Original Files]
echo.

if not exist "trl.exe" (
    echo ERROR: trl.exe was not found.
    echo Please place this file directly inside your Tomb Raider Legend game folder.
    echo.
    pause
    exit /b 1
)

if exist "nvidia.bik.disabled" (
    echo Restoring original nvidia.bik...
    ren "nvidia.bik.disabled" "nvidia.bik"
    echo.
    echo SUCCESS: Original file restored.
) else if exist "_backup_original\nvidia.bik" (
    echo Restoring from backup folder...
    copy "_backup_original\nvidia.bik" "nvidia.bik" >nul
    echo.
    echo SUCCESS: Original file restored from backup.
) else (
    echo No disabled file or backup found. Nothing to restore.
)

echo.
pause
