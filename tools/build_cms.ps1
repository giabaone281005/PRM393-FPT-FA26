#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$cmsRoot = Join-Path $repoRoot 'cms'
Push-Location -LiteralPath $cmsRoot
try {
    if (-not (Test-Path -LiteralPath (Join-Path $cmsRoot 'node_modules'))) {
        & npm ci --no-fund
        if ($LASTEXITCODE -ne 0) { throw 'CMS dependency installation failed.' }
    }
    & npm run build
    if ($LASTEXITCODE -ne 0) { throw 'CMS build failed.' }
    $webRoot = Join-Path $repoRoot 'build/admin-web'
    $cmsOutput = Join-Path $webRoot 'cms'
    New-Item -ItemType Directory -Path $cmsOutput -Force | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $cmsRoot 'dist') | Copy-Item -Destination $cmsOutput -Recurse -Force
    # The Admin entry opens the separate CMS; all its assets stay under /cms/.
    $entry = '<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0;url=/cms/"><title>Matlingo Admin</title></head><body><a href="/cms/">Mở Matlingo Admin</a><script>location.replace("/cms/")</script></body></html>'
    [IO.File]::WriteAllText((Join-Path $webRoot 'index.html'), $entry)
    Write-Host "CMS ready: $cmsOutput"
} finally {
    Pop-Location
}
