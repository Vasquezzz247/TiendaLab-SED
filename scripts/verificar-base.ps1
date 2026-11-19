$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$docker=(Get-Command docker -ErrorAction SilentlyContinue).Source
if(-not $docker){$docker='C:\Program Files\Docker\Docker\resources\bin\docker.exe'}
$php=Join-Path $root 'tools/php/php.exe'
$phpOptions=@('-d', "extension_dir=$root/tools/php/ext", '-d', 'extension=mysqli')
if(-not (Test-Path $php)){$php=(Get-Command php -ErrorAction Stop).Source; $phpOptions=@()}
function DbTest([string]$Mode='test') {
    & $php @phpOptions tests/database.test.php $Mode
    if($LASTEXITCODE -ne 0){throw "Prueba PHP fallo: $Mode"}
}
Push-Location $root
try {
    & $docker compose config --quiet
    if($LASTEXITCODE -ne 0){throw 'Compose invalido'}
    & $docker compose up -d --wait --wait-timeout 180
    if($LASTEXITCODE -ne 0){throw 'MariaDB no saludable'}
    DbTest
    $id=(& $docker compose ps -q db).Trim()
    $binding=(& $docker inspect --format '{{json .HostConfig.PortBindings}}' $id | ConvertFrom-Json).'3306/tcp'
    if($binding.Count -ne 1 -or $binding[0].HostIp -ne '127.0.0.1' -or $binding[0].HostPort -ne '3306'){throw 'Binding incorrecto'}
    Write-Output 'PASS: MariaDB publicada solo en 127.0.0.1:3306'
    & $docker inspect --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{end}}{{end}}' $id
    DbTest mark
    try {
        & $docker compose restart db
        if($LASTEXITCODE -ne 0){throw 'Restart fallo'}
        & $docker compose up -d --wait --wait-timeout 180
        if($LASTEXITCODE -ne 0){throw 'Health tras restart fallo'}
        DbTest verify-marker
        & $docker compose up -d --force-recreate --wait --wait-timeout 180 db
        if($LASTEXITCODE -ne 0){throw 'Recreacion fallo'}
        DbTest verify-marker
    } finally { DbTest restore }
    DbTest
    & $docker compose ps
} finally {Pop-Location}
