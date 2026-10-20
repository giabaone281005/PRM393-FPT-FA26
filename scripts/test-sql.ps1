param([switch]$Staging)
$ErrorActionPreference = 'Stop'
if (-not $Staging) { throw 'Chỉ chạy trên database staging. Truyền -Staging sau khi kiểm tra các biến PGHOST/PGDATABASE.' }
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) { throw 'Cần psql do bạn tự cài. Script không tải PostgreSQL và không thay đổi Supabase tự động.' }
if (-not $env:PGHOST -or -not $env:PGDATABASE -or -not $env:PGUSER) { throw 'Thiết lập PGHOST, PGDATABASE, PGUSER và PGPASSWORD trước khi chạy.' }
$repoRoot = Split-Path -Parent $PSScriptRoot
foreach ($name in @('commerce_regression.sql','payment_safety_regression.sql','demo_payment_regression.sql','parent_gate_multisession_regression.sql','role_learning_regression.sql','session_time_regression.sql','wrong_answer_review_regression.sql','learning_history_regression.sql','content_payment_operations.sql','family_communications_regression.sql','postflight.sql')) {
    & psql -X --set=ON_ERROR_STOP=1 --file=(Join-Path $repoRoot "supabase/tests/$name")
    if ($LASTEXITCODE -ne 0) { throw "SQL test failed: $name" }
}
