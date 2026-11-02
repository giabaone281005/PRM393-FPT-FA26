[CmdletBinding()]
param(
    [string]$DeviceId = 'emulator-5554',
    [string]$AvdName,
    [string]$TestFile = 'integration_test/user_journey_test.dart',
    [int]$BootTimeoutSeconds = 180,
    [int]$TestTimeoutMinutes = 10,
    [switch]$ColdBoot
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDirectory = Join-Path $repoRoot "build/android-e2e-$timestamp"
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$logFile = Join-Path $logDirectory 'user-journey-e2e.log'

function Write-Log {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    $line | Tee-Object -FilePath $logFile -Append
}

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found on PATH."
    }
}

function Get-DeviceState {
    $line = (& adb -s $DeviceId get-state 2>$null | Select-Object -First 1)
    if ($line) { return $line.Trim() }
    return $null
}

function Wait-ForBoot {
    param([int]$TimeoutSeconds)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $bootCompleted = (& adb -s $DeviceId shell getprop sys.boot_completed 2>$null | Select-Object -First 1).Trim()
        $packageManagerReady = (& adb -s $DeviceId shell getprop dev.bootcomplete 2>$null | Select-Object -First 1).Trim()
        if ($bootCompleted -eq '1' -and $packageManagerReady -eq '1') {
            Write-Log "Android emulator is ready: $DeviceId"
            return
        }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    throw "Timed out after $TimeoutSeconds seconds waiting for Android boot completion."
}

try {
    Require-Command 'flutter'
    Require-Command 'adb'

    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $TestFile))) {
        throw "Integration test file not found: $TestFile"
    }

    Write-Log "Repository: $repoRoot"
    Write-Log "Device: $DeviceId"
    Write-Log "Test: $TestFile"
    Write-Log "Logs: $logDirectory"

    $deviceState = Get-DeviceState
    if ($deviceState -ne 'device') {
        if (-not $AvdName) {
            throw "Device '$DeviceId' is not available. Start an Android emulator or pass -AvdName <name>."
        }
        Require-Command 'emulator'
        # A cold boot must not wipe emulator data; -no-snapshot-load only skips the saved snapshot.
        $emulatorArguments = @('-avd', $AvdName, '-no-snapshot-load')
        Write-Log "Starting AVD '$AvdName' with arguments: $($emulatorArguments -join ' ')"
        Start-Process -FilePath 'emulator' -ArgumentList $emulatorArguments -WorkingDirectory $repoRoot | Out-Null
        & adb wait-for-device | Out-Null
    } elseif ($ColdBoot) {
        Write-Log 'Cold boot requested, but an emulator is already running; no data will be wiped.'
    }

    Wait-ForBoot -TimeoutSeconds $BootTimeoutSeconds

    Write-Log 'Running Flutter integration test...'
    $flutterArguments = @(
        'test',
        $TestFile,
        '-d',
        $DeviceId,
        '--no-pub',
        '--reporter',
        'expanded',
        '--timeout',
        "${TestTimeoutMinutes}m"
    )
    & flutter @flutterArguments 2>&1 | Tee-Object -FilePath $logFile -Append
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Log 'E2E RESULT: PASS'
    } else {
        Write-Log "E2E RESULT: FAIL (exit code $exitCode)"
    }
    Write-Log "Full log: $logFile"
    exit $exitCode
} catch {
    Write-Log "E2E RESULT: ERROR - $($_.Exception.Message)"
    Write-Log "Full log: $logFile"
    exit 1
}
