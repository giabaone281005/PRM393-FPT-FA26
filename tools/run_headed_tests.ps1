#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$DeviceId,
    [string]$Avd,
    [string]$Config = 'config/app.e2e.json',
    [string]$ChromeDriverPath,
    [string]$ChromeBinary,
    [switch]$Offline,
    [switch]$PreflightOnly,
    [ValidateRange(30, 1800)][int]$BootTimeoutSeconds = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$payloadRoot = $root
# An extracted ZIP may be inside the repository. Resolve its nearest repo root.
while (-not (Test-Path -LiteralPath (Join-Path $root 'pubspec.yaml'))) {
    $parent = Split-Path -Parent $root
    if (-not $parent -or $parent -eq $root) {
        Write-Host 'Repository not found. Extract this package inside the Flutter repository.' -ForegroundColor Red
        exit 1
    }
    $root = $parent
}
if ($payloadRoot -ne $root) {
    $payloadAnalysis = Join-Path $payloadRoot 'analysis_options.yaml'
    if (-not (Test-Path -LiteralPath $payloadAnalysis)) {
        "analyzer:`n  exclude:`n    - '**'" | Set-Content -LiteralPath $payloadAnalysis -Encoding utf8
    }
}
Set-Location -LiteralPath $root
$run = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$logDir = Join-Path $root "build/headed-tests/$run"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$results = New-Object 'System.Collections.Generic.List[object]'
$secretFiles = New-Object 'System.Collections.Generic.List[string]'
$redactions = @()
$exitCode = 1
$driverProcess = $null
$previousWebResults = $env:HEADED_WEB_RESULTS

function Resolve-Tool([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) { throw "Missing $Name in PATH. See docs/HEADED_TESTS_ANDROID_WEB.md." }
    return $command.Source
}

function Resolve-Deno {
    $installed = Get-Command deno -ErrorAction SilentlyContinue
    if ($installed) { return $installed.Source }
    $toolDirectory = Join-Path $root 'build/headed-tools'
    $localDeno = Join-Path $toolDirectory 'node_modules/.bin/deno.cmd'
    if (-not (Test-Path -LiteralPath $localDeno)) {
        $npm = Resolve-Tool 'npm'
        Write-Host 'Deno is missing. Preparing local Deno 2.9.6 (first run requires internet)...'
        Invoke-Step 'prepare-deno' $npm @('install', '--prefix', $toolDirectory, '--no-save', '--package-lock=false', '--no-audit', '--no-fund', 'deno@2.9.6')
        if (-not (Test-Path -LiteralPath $localDeno)) {
            throw 'Deno installation did not produce deno.cmd. Check npm install permissions and the prepare-deno log.'
        }
    }
    return $localDeno
}

function Invoke-Step([string]$Name, [string]$Tool, [string[]]$Arguments) {
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $log = Join-Path $logDir "$Name.log"
    # Native tools write ordinary diagnostics to stderr in Windows PowerShell.
    $oldPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $Tool @Arguments 2>&1 | ForEach-Object {
            $line = "$_"
            foreach ($secret in $redactions) { $line = $line.Replace($secret, '[REDACTED]') }
            $line | Out-File -LiteralPath $log -Encoding utf8 -Append
            Write-Host $line
        }
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $oldPreference }
    $results.Add([pscustomobject]@{
        step = $Name; exitCode = $code; seconds = [Math]::Round($watch.Elapsed.TotalSeconds, 1)
    })
    if ($code -ne 0) { throw "$Name failed (exit $code). Log: $log" }
}

function Read-Native([string]$Tool, [string[]]$Arguments) {
    $output = & $Tool @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Tool failed: $Tool ($LASTEXITCODE)" }
    return ($output -join "`n")
}

function Get-AndroidDevices {
    $listing = Read-Native $script:adb @('devices')
    foreach ($line in ($listing -split "`n")) {
        if ($line -match '^(\S+)\s+device\s*$') { $Matches[1] }
    }
}

function Select-ItemFromList([string]$Label, [string[]]$Items) {
    if ($Items.Count -eq 0) { throw "No $Label found. Create an AVD in Android Studio Device Manager first." }
    if ($Items.Count -eq 1) { return $Items[0] }
    Write-Host "Multiple $Label found. Choose one (or pass -Avd / -DeviceId):"
    for ($i = 0; $i -lt $Items.Count; $i++) { Write-Host "$($i + 1). $($Items[$i])" }
    $choice = 0
    if (-not [int]::TryParse((Read-Host 'Number'), [ref]$choice) -or $choice -lt 1 -or $choice -gt $Items.Count) {
        throw 'Invalid selection.'
    }
    return $Items[$choice - 1]
}

try {
    if ($DeviceId -and $Avd) { throw 'Use either -DeviceId or -Avd.' }
    if ([bool]$ChromeDriverPath -ne [bool]$ChromeBinary) { throw 'Provide both -ChromeDriverPath and -ChromeBinary.' }
    foreach ($path in @($ChromeDriverPath, $ChromeBinary)) {
        if ($path -and -not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Browser tool not found: $path" }
    }
    $flutter = Resolve-Tool 'flutter'
    $dart = Resolve-Tool 'dart'
    $node = Resolve-Tool 'node'
    $deno = Resolve-Deno
    $git = Resolve-Tool 'git'
    $sdkCandidates = @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME)
    if ($env:LOCALAPPDATA) { $sdkCandidates += (Join-Path $env:LOCALAPPDATA 'Android/Sdk') }
    $localProperties = Join-Path $root 'android/local.properties'
    if (Test-Path -LiteralPath $localProperties) {
        $sdkLine = Get-Content -LiteralPath $localProperties | Where-Object { $_ -match '^sdk\.dir=' } | Select-Object -First 1
        if ($sdkLine) { $sdkCandidates += $sdkLine.Substring(8).Replace('\\', '\').Replace('\:', ':') }
    }
    $sdk = $sdkCandidates | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'platform-tools/adb.exe')) } | Select-Object -First 1
    if (-not $sdk) { throw 'Android SDK not found. Set ANDROID_SDK_ROOT or install Android Studio + SDK.' }
    $script:adb = Join-Path $sdk 'platform-tools/adb.exe'
    $emulator = Join-Path $sdk 'emulator/emulator.exe'
    $defines = @{}
    if (-not $Offline) {
        if (-not [IO.Path]::IsPathRooted($Config)) { $Config = Join-Path $root $Config }
        if (-not (Test-Path -LiteralPath $Config)) {
            throw "Missing $Config. Copy config/app.e2e.example.json to config/app.e2e.json and configure disposable test accounts. Or use -Offline for local tests only."
        }
        $configObject = Get-Content -LiteralPath $Config -Raw -Encoding utf8 | ConvertFrom-Json
        foreach ($property in $configObject.PSObject.Properties) { $defines[$property.Name] = $property.Value }
        $required = @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'E2E_EMAIL', 'E2E_PASSWORD', 'E2E_ID',
            'E2E_ADMIN_EMAIL', 'E2E_ADMIN_PASSWORD', 'E2E_ADMIN_ID', 'E2E_PHONE_EMAIL', 'E2E_PHONE_PASSWORD', 'E2E_PHONE_ID')
        foreach ($name in $required) {
            if (-not $defines[$name] -or "$($defines[$name])" -match 'replace-with|YOUR-TEST|your-publishable') {
                throw "Configure $name in the local E2E JSON."
            }
        }
        if ($defines['E2E_DISPOSABLE'] -ne $true) { throw 'E2E_DISPOSABLE must be true; use dedicated test accounts only.' }
        foreach ($name in @('E2E_ID', 'E2E_ADMIN_ID', 'E2E_PHONE_ID')) {
            $uuid = [Guid]::Empty
            if (-not [Guid]::TryParse($defines[$name], [ref]$uuid)) { throw "Invalid UUID in $name." }
        }
        if (@($defines['E2E_ID'], $defines['E2E_ADMIN_ID'], $defines['E2E_PHONE_ID'] | Select-Object -Unique).Count -ne 3) {
            throw 'Learner, Admin and phone-readiness must use three distinct accounts.'
        }
        if (@($defines.Keys | Where-Object { $_ -match 'SERVICE_ROLE|SECRET' }).Count -gt 0 -or
            "$($defines['SUPABASE_PUBLISHABLE_KEY'])" -like 'sb_secret_*') {
            throw 'Privileged secrets must not be passed to the test APK. Use a publishable key.'
        }
        $redactions = @($defines['E2E_PASSWORD'], $defines['E2E_ADMIN_PASSWORD'], $defines['E2E_PHONE_PASSWORD'])
    }
    Write-Host "Preflight OK. Logs: $logDir"
    if ($PreflightOnly) { $exitCode = 0; return }
    $browser = & (Join-Path $PSScriptRoot 'prepare_headed_browser.ps1') -ChromeDriverPath $ChromeDriverPath -ChromeBinary $ChromeBinary

    # Open the visible Android emulator before running checks. Never wipe AVD data.
    Read-Native $adb @('start-server') | Out-Null
    $devices = @(Get-AndroidDevices)
    if ($DeviceId) {
        if ($DeviceId -notin $devices) { throw "Device $DeviceId is offline, unauthorized or absent. Check adb devices." }
    } elseif (-not $Avd -and $devices.Count -gt 0) {
        $DeviceId = Select-ItemFromList 'Android devices' $devices
    } else {
        if (-not (Test-Path -LiteralPath $emulator)) { throw 'Install Android Emulator in Android Studio SDK Manager.' }
        $avds = @((Read-Native $emulator @('-list-avds')) -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if (-not $Avd) { $Avd = Select-ItemFromList 'Android virtual devices' $avds }
        if ($Avd -notin $avds) { throw "Unknown AVD: $Avd" }
        # Reuse only the requested AVD, not a different booting emulator.
        function Find-AvdDevice {
            foreach ($serial in @(Get-AndroidDevices)) {
                if ($serial -like 'emulator-*') {
                    $name = Read-Native $adb @('-s', $serial, 'emu', 'avd', 'name')
                    if (($name -split "`n")[0].Trim() -eq $Avd) { return $serial }
                }
            }
        }
        $DeviceId = Find-AvdDevice
        if (-not $DeviceId) {
            if ($Avd -notmatch '^[a-zA-Z0-9_.-]+$') { throw 'AVD name must contain only letters, numbers, dot, underscore or hyphen.' }
            Start-Process -FilePath $emulator -ArgumentList @('-avd', $Avd) -WindowStyle Hidden `
                -RedirectStandardOutput (Join-Path $logDir 'emulator.log') `
                -RedirectStandardError (Join-Path $logDir 'emulator-error.log') | Out-Null
            $deadline = [DateTime]::UtcNow.AddSeconds($BootTimeoutSeconds)
            do {
                Start-Sleep -Seconds 2
                $DeviceId = Find-AvdDevice
            } until ($DeviceId -or [DateTime]::UtcNow -gt $deadline)
            if (-not $DeviceId) { throw 'Emulator startup timed out. Check emulator logs, virtualization and SDK image.' }
        }
    }
    $deadline = [DateTime]::UtcNow.AddSeconds($BootTimeoutSeconds)
    do {
        $booted = (Read-Native $adb @('-s', $DeviceId, 'shell', 'getprop', 'sys.boot_completed')).Trim() -eq '1'
        if (-not $booted) { Start-Sleep -Seconds 2 }
    } until ($booted -or [DateTime]::UtcNow -gt $deadline)
    if (-not $booted) { throw "Android boot timed out: $DeviceId" }
    Write-Host "Headed target: $DeviceId"

    Invoke-Step 'pub-get' $flutter @('pub', 'get')
    Invoke-Step 'analyze' $flutter @('analyze', '--no-pub')
    Invoke-Step 'unit-widget-tests' $flutter @('test', 'test', '--no-pub', '--reporter', 'expanded')
    Invoke-Step 'evaluator-parity' $node @('supabase/tests/evaluator_parity.mjs')
    foreach ($check in @('diverse', 'depth', 'space')) {
        Invoke-Step "check-$check" $dart @("tools/check_$check.dart")
    }
    Invoke-Step 'learning-check' $deno @('check', 'supabase/functions/learning-api/index.ts')
    Invoke-Step 'learning-lint' $deno @('lint', 'supabase/functions/learning-api/index.ts', 'supabase/functions/learning-api/handler.ts', 'supabase/functions/_shared/http.ts', 'supabase/tests/learning_handler_test.ts')
    Invoke-Step 'tutor-check' $deno @('check', 'supabase/functions/tutor-chat/index.ts')
    Invoke-Step 'tutor-lint' $deno @('lint', 'supabase/functions/tutor-chat', 'supabase/tests/tutor_handler_test.ts', 'supabase/tests/app_knowledge_test.ts')
    Invoke-Step 'edge-tests' $deno @('test', 'supabase/tests/learning_handler_test.ts', 'supabase/tests/tutor_handler_test.ts', 'supabase/tests/app_knowledge_test.ts')
    Invoke-Step 'headed-user-journey' $flutter @('test', 'integration_test/user_journey_test.dart', '-d', $DeviceId, '--no-pub', '--reporter', 'expanded')
    if (-not $Offline) {
        # Allowlist inputs: never forward arbitrary config fields/secrets to APK.
        $full = @{}
        foreach ($name in @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'E2E_EMAIL', 'E2E_PASSWORD', 'E2E_ID', 'E2E_ADMIN_ID')) { $full[$name] = $defines[$name] }
        $full['E2E_RUN'] = $run
        $full['E2E_TOPIC'] = "headed-$run"
        $fullConfig = Join-Path $logDir 'full-stack.private.json'
        $phoneConfig = Join-Path $logDir 'phone.private.json'
        $webConfig = Join-Path $logDir 'admin-web.private.json'
        $secretFiles.Add($fullConfig)
        $secretFiles.Add($phoneConfig)
        $secretFiles.Add($webConfig)
        $full | ConvertTo-Json | Set-Content -LiteralPath $fullConfig -Encoding utf8
        $phone = @{
            SUPABASE_URL = $defines['SUPABASE_URL']; SUPABASE_PUBLISHABLE_KEY = $defines['SUPABASE_PUBLISHABLE_KEY']
            E2E_EMAIL = $defines['E2E_PHONE_EMAIL']; E2E_PASSWORD = $defines['E2E_PHONE_PASSWORD']; E2E_ID = $defines['E2E_PHONE_ID']
        }
        $phone | ConvertTo-Json | Set-Content -LiteralPath $phoneConfig -Encoding utf8
        $web = $full.Clone()
        $web['E2E_ADMIN_EMAIL'] = $defines['E2E_ADMIN_EMAIL']
        $web['E2E_ADMIN_PASSWORD'] = $defines['E2E_ADMIN_PASSWORD']
        $web | ConvertTo-Json | Set-Content -LiteralPath $webConfig -Encoding utf8
        Invoke-Step 'headed-learner-android' $flutter @('test', 'integration_test/full_stack_journey_test.dart', '-d', $DeviceId, '--no-pub', '--reporter', 'expanded', "--dart-define-from-file=$fullConfig")
        Invoke-Step 'headed-phone-readiness' $flutter @('test', 'integration_test/phone_readiness_test.dart', '-d', $DeviceId, '--no-pub', '--reporter', 'expanded', "--dart-define-from-file=$phoneConfig")
    }

    # ChromeDriver owns a fresh browser profile. Use a free loopback port and
    # stop only the driver process launched by this run, even when tests fail.
    $portProbe = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, 0)
    $portProbe.Start()
    $driverPort = $portProbe.LocalEndpoint.Port
    $portProbe.Stop()
    $driverProcess = Start-Process -FilePath $browser.driver -ArgumentList @("--port=$driverPort", '--allowed-ips=127.0.0.1') `
        -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logDir 'chromedriver.log') `
        -RedirectStandardError (Join-Path $logDir 'chromedriver-error.log')
    $driverDeadline = [DateTime]::UtcNow.AddSeconds(30)
    $driverReady = $false
    do {
        if ($driverProcess.HasExited) { throw 'ChromeDriver exited during startup. Check chromedriver logs.' }
        try {
            $status = Invoke-RestMethod -Uri "http://127.0.0.1:$driverPort/status" -TimeoutSec 2
            $driverReady = $status.value.ready -eq $true
        } catch { Start-Sleep -Milliseconds 300 }
    } until ($driverReady -or [DateTime]::UtcNow -gt $driverDeadline)
    if (-not $driverReady) { throw 'ChromeDriver startup timed out.' }
    $env:HEADED_WEB_RESULTS = $logDir
    $webTarget = if ($Offline) { 'test/admin_web_smoke.dart' } else { 'integration_test/admin_web_journey_test.dart' }
    $webArguments = @('drive', '--driver=test_driver/headed_web.dart', "--target=$webTarget", '-d', 'web-server',
        '--no-headless', '--browser-name=chrome', '--browser-dimension=1440x1000', "--driver-port=$driverPort", "--chrome-binary=$($browser.chrome)", '--no-pub')
    if (-not $Offline) { $webArguments += "--dart-define-from-file=$webConfig" }
    Invoke-Step 'headed-admin-web' $flutter $webArguments
    # Rebuild without fixture credentials. Never distribute integration APKs.
    Invoke-Step 'normal-debug-build' $flutter @('build', 'apk', '--debug', '--no-pub')
    Invoke-Step 'admin-web-build' $flutter @('build', 'web', '--target', 'lib/admin_main.dart', '--output', 'build/admin-web', '--no-pub')
    Invoke-Step 'diff-check' $git @('diff', '--check')
    $exitCode = 0
} catch {
    $message = $_.Exception.Message
    foreach ($secret in $redactions) { $message = $message.Replace($secret, '[REDACTED]') }
    Write-Host "`nFAILED: $message" -ForegroundColor Red
} finally {
    if ($null -ne $driverProcess -and -not $driverProcess.HasExited) { Stop-Process -Id $driverProcess.Id -Force }
    $env:HEADED_WEB_RESULTS = $previousWebResults
    foreach ($path in $secretFiles) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force } }
    [pscustomobject]@{
        run = $run; success = ($exitCode -eq 0); offline = [bool]$Offline
        preflightOnly = [bool]$PreflightOnly; learnerDevice = $DeviceId; adminPlatform = 'web'; steps = @($results.ToArray())
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $logDir 'result.json') -Encoding utf8
    Write-Host "`nResults: $logDir"
    if ($exitCode -eq 0) {
        if ($PreflightOnly) { Write-Host 'PREFLIGHT PASSED (tests not run).' -ForegroundColor Green }
        elseif ($Offline) { Write-Host 'LOCAL SUITE PASSED (Android learner + browser Admin smoke). Live backend tests were excluded (-Offline).' -ForegroundColor Yellow }
        else { Write-Host 'ALL CONFIGURED STEPS PASSED.' -ForegroundColor Green }
    }
}
exit $exitCode
