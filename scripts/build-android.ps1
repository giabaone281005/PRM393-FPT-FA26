param([ValidateSet('debug','release')][string]$Mode='debug',[string]$Config='config/app.json')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot
if (-not (Test-Path -LiteralPath $Config)) { throw 'Sao chép config/app.example.json thành config/app.json và điền thông tin public của Supabase.' }
$appConfig=Get-Content -LiteralPath $Config -Raw | ConvertFrom-Json
if (-not $appConfig.SUPABASE_URL.StartsWith('https://') -or $appConfig.SUPABASE_URL.Contains('YOUR_') -or $appConfig.SUPABASE_ANON_KEY.Contains('YOUR_')) { throw 'Cấu hình Supabase chưa hợp lệ.' }
if ($Mode -eq 'release' -and -not (Test-Path -LiteralPath 'android/key.properties')) { throw 'Cần cấu hình khóa ký phát hành trong android/key.properties.' }
& flutter analyze --no-pub
if ($LASTEXITCODE -ne 0) { throw 'Analyze failed' }
& flutter test --no-pub
if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed' }
& node --test test_backend/handlers.test.mjs test_backend/operations.test.mjs test_backend/vnpay.test.mjs
if ($LASTEXITCODE -ne 0) { throw 'Backend tests failed' }
& flutter build apk "--$Mode" --no-pub "--dart-define-from-file=$Config"
if ($LASTEXITCODE -ne 0) { throw 'Android build failed' }
