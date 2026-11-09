#Requires -Version 5.1
# Host-only smoke tests: fake toolchain, no emulator/network/database required.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sandbox = Join-Path $root ('build/runner-smoke-' + [Guid]::NewGuid().ToString('N'))
$bin = Join-Path $sandbox 'bin'
$sdk = Join-Path $sandbox 'sdk'
New-Item -ItemType Directory -Force -Path $bin, (Join-Path $sdk 'platform-tools'), (Join-Path $sdk 'emulator') | Out-Null
$oldPath = $env:PATH
$oldSdk = $env:ANDROID_SDK_ROOT
$oldCalls = $env:HEADED_SMOKE_CALLS
$oldFail = $env:HEADED_SMOKE_FAIL
$oldBoot = $env:HEADED_SMOKE_BOOT
$oldDriverPid = $env:HEADED_SMOKE_DRIVER_PID
$oldWebFail = $env:HEADED_SMOKE_FAIL_WEB
$env:HEADED_SMOKE_CALLS = Join-Path $sandbox 'calls.txt'
$runner = Join-Path $PSScriptRoot 'run_headed_tests.ps1'

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Run-Runner([string[]]$RunnerArgs) {
    # Separate process verifies real exit codes and script scope.
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner @RunnerArgs -ChromeDriverPath $fakeBrowser -ChromeBinary $fakeBrowser 2>&1
    $script:code = $LASTEXITCODE
    return ($output -join "`n")
}

try {
    foreach ($tool in @('flutter', 'dart', 'node', 'deno', 'git')) {
        @"
@echo off
echo $tool %*>>"%HEADED_SMOKE_CALLS%"
if "%HEADED_SMOKE_FAIL%"=="$tool" exit /b 7
if "%1"=="drive" if "%HEADED_SMOKE_FAIL_WEB%"=="1" exit /b 8
echo mock $tool OK
exit /b 0
"@ | Set-Content -LiteralPath (Join-Path $bin "$tool.cmd") -Encoding ascii
    }
    # The runner resolves adb.exe, so use a tiny .NET executable with fixed output.
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Diagnostics;
public class HeadedFakeAdb {
    public static void Main(string[] args) {
        if (args.Length > 0 && args[0].StartsWith("--port=")) {
            File.WriteAllText(Environment.GetEnvironmentVariable("HEADED_SMOKE_DRIVER_PID"), Process.GetCurrentProcess().Id.ToString());
            var server = new TcpListener(IPAddress.Loopback, Int32.Parse(args[0].Substring(7)));
            server.Start();
            while (true) {
                using (var client = server.AcceptTcpClient()) using (var stream = client.GetStream()) {
                    var buffer = new byte[4096]; stream.Read(buffer, 0, buffer.Length);
                    var body = "{\"value\":{\"ready\":true}}";
                    var data = Encoding.ASCII.GetBytes("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " + body.Length + "\r\nConnection: close\r\n\r\n" + body);
                    stream.Write(data, 0, data.Length);
                }
            }
        }
        var marker = Environment.GetEnvironmentVariable("HEADED_SMOKE_BOOT");
        if (args.Length > 0 && args[0] == "-list-avds") { Console.WriteLine("Smoke_AVD"); return; }
        if (args.Length > 0 && args[0] == "-avd") { File.WriteAllText(marker, "started"); return; }
        if (args.Length > 0 && args[0] == "devices") {
            Console.WriteLine("List of devices attached");
            if (String.IsNullOrEmpty(marker) || File.Exists(marker)) { Console.WriteLine("emulator-9999\tdevice"); }
        } else if (Array.IndexOf(args, "getprop") >= 0) { Console.WriteLine("1"); }
        else if (Array.IndexOf(args, "avd") >= 0) { Console.WriteLine("Smoke_AVD\nOK"); }
    }
}
'@ -OutputAssembly (Join-Path $sdk 'platform-tools/adb.exe') -OutputType ConsoleApplication
    Copy-Item -LiteralPath (Join-Path $sdk 'platform-tools/adb.exe') -Destination (Join-Path $sdk 'emulator/emulator.exe')
    $fakeBrowser = Join-Path $sdk 'platform-tools/adb.exe'
    $env:PATH = "$bin;$oldPath"
    $env:ANDROID_SDK_ROOT = $sdk
    $env:HEADED_SMOKE_FAIL = ''
    $env:HEADED_SMOKE_BOOT = ''
    $env:HEADED_SMOKE_DRIVER_PID = Join-Path $sandbox 'driver-pid.txt'
    $env:HEADED_SMOKE_FAIL_WEB = ''
    $config = Join-Path $sandbox 'config.json'
    $settings = @{
        SUPABASE_URL = 'https://example.supabase.co'; SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_test'
        E2E_DISPOSABLE = $true
        E2E_EMAIL = 'learner@example.test'; E2E_PASSWORD = 'test-secret-learner'; E2E_ID = [Guid]::NewGuid().ToString()
        E2E_ADMIN_EMAIL = 'admin@example.test'; E2E_ADMIN_PASSWORD = 'test-secret-admin'; E2E_ADMIN_ID = [Guid]::NewGuid().ToString()
        E2E_PHONE_EMAIL = 'phone@example.test'; E2E_PHONE_PASSWORD = 'test-secret-phone'; E2E_PHONE_ID = [Guid]::NewGuid().ToString()
    }
    $settings | ConvertTo-Json | Set-Content -LiteralPath $config -Encoding utf8
    $output = Run-Runner @('-Config', $config, '-DeviceId', 'emulator-9999')
    Assert ($code -eq 0) "Full orchestration failed: $output"
    $calls = Get-Content -LiteralPath $env:HEADED_SMOKE_CALLS -Raw
    foreach ($target in @('user_journey_test.dart', 'full_stack_journey_test.dart', 'phone_readiness_test.dart', 'admin_web_journey_test.dart', 'admin_main.dart')) {
        Assert ($calls.Contains($target)) "Missing execution: $target"
    }
    Assert (-not $calls.Contains('test-secret')) 'Credential leaked into command arguments.'
    Assert ($output.Contains('ALL CONFIGURED STEPS PASSED')) 'Missing full completion status.'
    Assert ($calls.Contains('--no-headless') -and $calls.Contains('-d web-server')) 'Admin did not use a headed browser.'
    Assert (-not ($calls -match 'flutter test [^\r\n]*admin_web')) 'Admin was run as an Android test.'
    $driverPid = [int](Get-Content -LiteralPath $env:HEADED_SMOKE_DRIVER_PID -Raw)
    Assert (-not (Get-Process -Id $driverPid -ErrorAction SilentlyContinue)) 'ChromeDriver leaked after success.'
    $resultPath = [regex]::Match($output, 'Results: ([^\r\n]+)').Groups[1].Value.Trim()
    Assert (@(Get-ChildItem -LiteralPath $resultPath -Filter '*.private.json').Count -eq 0) 'Temporary credentials not cleaned.'
    $result = Get-Content -LiteralPath (Join-Path $resultPath 'result.json') -Raw | ConvertFrom-Json
    Assert ($result.success -and $result.steps.Count -gt 15) 'Incomplete result manifest.'

    Remove-Item -LiteralPath $env:HEADED_SMOKE_CALLS
    $env:HEADED_SMOKE_BOOT = Join-Path $sandbox 'booted.txt'
    $output = Run-Runner @('-Offline', '-Avd', 'Smoke_AVD')
    Assert ($code -eq 0 -and (Test-Path -LiteralPath $env:HEADED_SMOKE_BOOT)) "Automatic AVD launch failed: $output"
    $calls = Get-Content -LiteralPath $env:HEADED_SMOKE_CALLS -Raw
    Assert (-not $calls.Contains('full_stack_journey_test.dart')) 'Offline mode invoked live tests.'
    Assert ($calls.Contains('admin_web_smoke.dart')) 'Offline mode omitted browser Admin smoke.'
    Assert ($output.Contains('LOCAL SUITE PASSED')) 'Offline result was not labeled.'
    $env:HEADED_SMOKE_BOOT = ''

    Remove-Item -LiteralPath $env:HEADED_SMOKE_CALLS
    $env:HEADED_SMOKE_FAIL = 'flutter'
    $output = Run-Runner @('-Offline', '-DeviceId', 'emulator-9999')
    Assert ($code -ne 0) 'Failed child tool returned success.'
    $calls = @(Get-Content -LiteralPath $env:HEADED_SMOKE_CALLS)
    Assert ($calls.Count -eq 1) 'Runner continued after failed pub get.'
    Assert (-not $output.Contains('ALL CONFIGURED STEPS PASSED')) 'False success after failure.'

    $env:HEADED_SMOKE_FAIL = ''
    $env:HEADED_SMOKE_FAIL_WEB = '1'
    $output = Run-Runner @('-Offline', '-DeviceId', 'emulator-9999')
    Assert ($code -ne 0 -and $output.Contains('headed-admin-web failed')) 'Web failure returned success.'
    $driverPid = [int](Get-Content -LiteralPath $env:HEADED_SMOKE_DRIVER_PID -Raw)
    Assert (-not (Get-Process -Id $driverPid -ErrorAction SilentlyContinue)) 'ChromeDriver leaked after web failure.'
    $env:HEADED_SMOKE_FAIL_WEB = ''
    $settings.E2E_PHONE_ID = $settings.E2E_ID
    $settings | ConvertTo-Json | Set-Content -LiteralPath $config -Encoding utf8
    $output = Run-Runner @('-Config', $config, '-PreflightOnly')
    Assert ($code -ne 0 -and $output.Contains('distinct accounts')) 'Shared learner fixture accepted.'
    $output = Run-Runner @('-Config', (Join-Path $sandbox 'missing.json'), '-PreflightOnly')
    Assert ($code -ne 0 -and $output.Contains('Missing')) 'Missing config accepted.'
    $output = Run-Runner @('-Offline', '-PreflightOnly')
    Assert ($code -eq 0 -and $output.Contains('tests not run')) 'Offline preflight failed.'
    Write-Host 'Headed runner smoke tests passed (mock orchestration, failure propagation, fixture isolation, missing config, preflight, cleanup).'
} finally {
    $env:PATH = $oldPath
    $env:ANDROID_SDK_ROOT = $oldSdk
    $env:HEADED_SMOKE_CALLS = $oldCalls
    $env:HEADED_SMOKE_FAIL = $oldFail
    $env:HEADED_SMOKE_BOOT = $oldBoot
    $env:HEADED_SMOKE_DRIVER_PID = $oldDriverPid
    $env:HEADED_SMOKE_FAIL_WEB = $oldWebFail
    # Keep the ignored sandbox/logs as verification evidence; no recursive deletion.
}
