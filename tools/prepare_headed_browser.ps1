#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ChromeDriverPath,
    [string]$ChromeBinary,
    [string]$CacheDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'build/headed-browser')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ChromeDriverPath -or $ChromeBinary) {
    if (-not $ChromeDriverPath -or -not $ChromeBinary) { throw 'Provide both -ChromeDriverPath and -ChromeBinary.' }
    foreach ($path in @($ChromeDriverPath, $ChromeBinary)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Browser tool not found: $path" }
    }
    return [pscustomobject]@{
        driver = (Resolve-Path -LiteralPath $ChromeDriverPath).Path
        chrome = (Resolve-Path -LiteralPath $ChromeBinary).Path
    }
}

# Use a matched Chrome for Testing + ChromeDriver pair, independent of members'
# installed browser versions. Cache stays local and never enters Git.
$platform = if ([Environment]::Is64BitOperatingSystem) { 'win64' } else { 'win32' }
$manifestFile = Join-Path $CacheDirectory 'version.txt'
$version = if (Test-Path -LiteralPath $manifestFile) { (Get-Content -LiteralPath $manifestFile -Raw).Trim() } else { '' }
if (-not $version) {
    Write-Host 'Preparing matching Chrome for Testing and ChromeDriver (first run requires internet)...'
    $manifest = Invoke-RestMethod -Uri 'https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json' -TimeoutSec 60
    $version = $manifest.channels.Stable.version
}
if ($version -notmatch '^\d+\.\d+\.\d+\.\d+$') { throw 'Invalid Chrome for Testing version.' }
$destination = Join-Path $CacheDirectory $version
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$oldProgress = $ProgressPreference
try {
    $ProgressPreference = 'SilentlyContinue'
    foreach ($package in @('chrome', 'chromedriver')) {
        $executable = Join-Path $destination "$package-$platform/$package.exe"
        if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
            $archive = Join-Path $destination "$package-$platform.zip"
            $uri = "https://storage.googleapis.com/chrome-for-testing-public/$version/$platform/$package-$platform.zip"
            Write-Host "Downloading $package $version ($platform)..."
            Invoke-WebRequest -Uri $uri -OutFile $archive -UseBasicParsing -TimeoutSec 300
            Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
            if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw "Archive is missing $package.exe" }
        }
    }
    $version | Set-Content -LiteralPath $manifestFile -Encoding ascii
} finally { $ProgressPreference = $oldProgress }
return [pscustomobject]@{
    driver = Join-Path $destination "chromedriver-$platform/chromedriver.exe"
    chrome = Join-Path $destination "chrome-$platform/chrome.exe"
}
