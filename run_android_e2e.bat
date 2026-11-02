@echo off
setlocal

cd /d "%~dp0"

echo ========================================
echo Matlingo Android E2E Test
echo ========================================
echo.

echo Running emulator E2E test...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_android_e2e.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
    echo E2E TEST RESULT: PASS
) else (
    echo E2E TEST RESULT: FAIL ^(exit code %EXIT_CODE%^^)
)
echo.
echo Press any key to close this window...
pause >nul

exit /b %EXIT_CODE%
