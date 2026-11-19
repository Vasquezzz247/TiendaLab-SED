param([int]$Port = 8000, [int]$DisabledPort = 8002)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$phpPath = Join-Path $projectRoot 'tools/php/php.exe'
if (-not (Test-Path -LiteralPath $phpPath)) { $phpPath = (Get-Command php -ErrorAction Stop).Source }
Push-Location $projectRoot
try {
    $files = Get-ChildItem -Path app,demo,public -Filter '*.php' -Recurse
    foreach ($file in $files) { & $phpPath -l $file.FullName; if ($LASTEXITCODE -ne 0) { throw "PHP inválido: $($file.FullName)" } }
    & $phpPath tests/security.test.php
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron pruebas de escape y guardia local' }
    & node --check public/assets/js/app.js
    if ($LASTEXITCODE -ne 0) { throw 'JavaScript inválido' }
    & node --test tests/frontend.test.cjs
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron pruebas de cantidades/IVA' }
    & node tests/http.test.cjs $Port $DisabledPort
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron pruebas HTTP' }
} finally { Pop-Location }
