@echo off
setlocal
rem Resolve relative to this file, even when launched outside the repository.
rem Learner runs on Android; Admin runs in a visible Chrome web browser.
if "%~1"=="" goto demo
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_headed_tests.ps1" %*
goto finished
:demo
echo Starting LOCAL DEMO: Android learner + Admin web with mock data.
echo Live backend tests require a configured E2E account file.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_headed_tests.ps1" -Offline
:finished
set "test_exit=%ERRORLEVEL%"
echo.
if not "%MATHLINGO_NO_PAUSE%"=="1" pause
exit /b %test_exit%
