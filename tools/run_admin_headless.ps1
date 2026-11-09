#Requires -Version 5.1
[CmdletBinding()]
param([switch]$SkipUnitTests)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$logDirectory = Join-Path $repoRoot ('build/admin-headless-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$flutterTool = (Get-Command flutter -ErrorAction Stop).Source
$browser = & (Join-Path $PSScriptRoot 'prepare_headed_browser.ps1')
$driverProcess = $null
$previousResults = $env:HEADED_WEB_RESULTS
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$listener.Start()
$driverPort = $listener.LocalEndpoint.Port
$listener.Stop()
Push-Location -LiteralPath $repoRoot
try {
    if (-not $SkipUnitTests) {
        & $flutterTool test --no-pub --reporter expanded 2>&1 | Tee-Object -FilePath (Join-Path $logDirectory 'flutter-tests.log')
        if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
    }
    $driverProcess = Start-Process -FilePath $browser.driver -ArgumentList @("--port=$driverPort", '--allowed-ips=127.0.0.1') -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $logDirectory 'chromedriver.log') -RedirectStandardError (Join-Path $logDirectory 'chromedriver-error.log')
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        if ($driverProcess.HasExited) { throw 'ChromeDriver exited before becoming ready.' }
        try { $ready = (Invoke-RestMethod -Uri "http://127.0.0.1:$driverPort/status" -TimeoutSec 1).value.ready } catch { Start-Sleep -Milliseconds 200 }
    } until ($ready -or [DateTime]::UtcNow -gt $deadline)
    if (-not $ready) { throw 'ChromeDriver startup timed out.' }
    $env:HEADED_WEB_RESULTS = $logDirectory
    & $flutterTool drive --driver=test_driver/headed_web.dart --target=test/admin_headless_smoke.dart -d web-server `
        --headless --browser-name=chrome --browser-dimension=1440x1100 "--driver-port=$driverPort" "--chrome-binary=$($browser.chrome)" --no-pub `
        2>&1 | Tee-Object -FilePath (Join-Path $logDirectory 'browser-tests.log')
    if ($LASTEXITCODE -ne 0) { throw 'Headless Admin browser tests failed.' }
    Write-Host "PASS: Admin headless results: $logDirectory"
} finally {
    $env:HEADED_WEB_RESULTS = $previousResults
    if ($driverProcess -and -not $driverProcess.HasExited) { Stop-Process -Id $driverProcess.Id -ErrorAction SilentlyContinue }
    Pop-Location
}
