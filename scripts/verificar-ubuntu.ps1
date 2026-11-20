# Corre la suite HTTP/BD (tests/backend.test.cjs) contra la tienda REAL instalada en la VM de Ubuntu (Apache + PHP del sistema).
# El HTTP va por el reenvio NAT 127.0.0.1:8080; las lecturas/escrituras SQL de los datos de prueba, por un tunel SSH que
# escucha solo en 127.0.0.1. La clave SQL de la aplicacion se lee de la VM y vive solo en variables de entorno del proceso:
# nunca se imprime ni se guarda. Usa datos ficticios con prefijo propio y los limpia al terminar (comprueba el SHA-256 del seed).
param(
    [string]$Carpeta = (Join-Path $HOME 'Downloads\TiendaLab-VM'),
    [int]$PuertoWeb = 8080, [int]$PuertoSsh = 2222, [int]$PuertoTunel = 33306, [int]$PuertoSinBase = 8012
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$clave = Join-Path $Carpeta 'id_tiendalab'
$php = Join-Path $root 'tools/php/php.exe'
$options = @('-d', 'display_errors=0', '-d', 'upload_max_filesize=2M', '-d', 'post_max_size=3M')
if (Test-Path $php) { $options += @('-d', "extension_dir=$root/tools/php/ext", '-d', 'extension=mysqli', '-d', 'extension=fileinfo', '-d', 'extension=gd', '-d', 'extension=mbstring') }
else { $php = (Get-Command php -ErrorAction Stop).Source }
$sshArgs = @('-i', $clave, '-p', $PuertoSsh, '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=NUL', '-o', 'LogLevel=ERROR')
$tunnel = $null; $server = $null; $created = $false
$old = @{ DB_HOST = $env:DB_HOST; DB_PORT = $env:DB_PORT; DB_PASSWORD = $env:DB_PASSWORD; PHP = $env:TIENDALAB_TEST_PHP; OPT = $env:TIENDALAB_TEST_PHP_OPTIONS; PROTO = $env:TIENDALAB_PROTOTIPO }
Push-Location $root
try {
    if (-not (Test-Path (Join-Path $root 'tmp'))) { New-Item -ItemType Directory (Join-Path $root 'tmp') | Out-Null }
    if (Test-Path (Join-Path $root 'tmp/fase03-fixtures.json')) { throw 'Hay datos de prueba pendientes en tmp/fase03-fixtures.json: revisalos antes de repetir.' }
    foreach ($port in @($PuertoTunel, $PuertoSinBase)) {
        if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) { throw "Puerto local $port ocupado." }
    }
    try { $r = Invoke-WebRequest "http://127.0.0.1:$PuertoWeb/login.php" -UseBasicParsing -TimeoutSec 10; if ($r.StatusCode -ne 200) { throw 'login no responde 200' } }
    catch { throw "La tienda de la VM no responde en 127.0.0.1:$PuertoWeb ($($_.Exception.Message))" }

    # Clave SQL de la aplicacion (solo en memoria de este proceso).
    $previous = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $linea = (& ssh @sshArgs tiendalab@127.0.0.1 "sudo grep '^DB_PASSWORD=' /var/www/tiendalab/.env" 2>$null | Out-String).Trim()
    $ErrorActionPreference = $previous
    if ($linea -notmatch '^DB_PASSWORD=(.+)$') { throw 'No se pudo leer DB_PASSWORD de la VM.' }
    $env:DB_PASSWORD = $Matches[1]; $env:DB_HOST = '127.0.0.1'; $env:DB_PORT = "$PuertoTunel"

    # Tunel SSH hacia el 127.0.0.1:3306 de la VM, escuchando solo en el 127.0.0.1 de este equipo.
    $tunnel = Start-Process -FilePath (Get-Command ssh).Source -ArgumentList ($sshArgs + @('-o', 'ExitOnForwardFailure=yes', '-N', '-L', "127.0.0.1:${PuertoTunel}:127.0.0.1:3306", 'tiendalab@127.0.0.1')) -WindowStyle Hidden -PassThru
    for ($i = 0; $i -lt 40 -and -not (Get-NetTCPConnection -State Listen -LocalPort $PuertoTunel -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Milliseconds 250 }
    if (-not (Get-NetTCPConnection -State Listen -LocalPort $PuertoTunel -ErrorAction SilentlyContinue)) { throw 'El tunel SSH no abrio.' }

    $null = & $php @options tests/backend-fixtures.php setup
    if ($LASTEXITCODE -ne 0) { throw 'No se prepararon los datos de prueba (revisar tmp/fase03-fixtures.json antes de repetir).' }
    $created = $true
    Write-Output 'PASS: datos de prueba aislados creados en la MariaDB de la VM con el usuario de la aplicacion.'

    # Servidor local SIN base de datos (puerto SQL 1) para comprobar el error controlado 503.
    $env:TIENDALAB_PROTOTIPO = '0'; $env:DB_PORT = '1'
    $server = Start-Process -FilePath $php -ArgumentList ($options + @('-S', "127.0.0.1:$PuertoSinBase", '-t', 'public', 'scripts/router.php')) -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput 'tmp/ubuntu-sinbase.out.log' -RedirectStandardError 'tmp/ubuntu-sinbase.err.log'
    $env:DB_PORT = "$PuertoTunel"
    for ($i = 0; $i -lt 40; $i++) { try { if ((Invoke-WebRequest "http://127.0.0.1:$PuertoSinBase/login.php" -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200) { break } } catch { Start-Sleep -Milliseconds 150 } }

    $env:TIENDALAB_TEST_PHP = $php
    $env:TIENDALAB_TEST_PHP_OPTIONS = ConvertTo-Json -InputObject $options -Compress
    # Las dos "sesiones concurrentes" de la suite van al mismo Apache: concurrencia real entre dos solicitudes HTTP.
    & node tests/backend.test.cjs $PuertoWeb $PuertoWeb $PuertoSinBase
    $codigoSuite = $LASTEXITCODE
    $codigoRollback = 1
    if ($codigoSuite -eq 0) { & $php @options tests/backend-fixtures.php transaction; $codigoRollback = $LASTEXITCODE }
    if ($codigoSuite -ne 0) { throw 'Fallo la suite HTTP/BD contra Ubuntu.' }
    if ($codigoRollback -ne 0) { throw 'Fallo la prueba de rollback SQL contra Ubuntu.' }
    Write-Output "PASS: suite HTTP/BD y rollbacks contra Apache/PHP/MariaDB de la VM Ubuntu (127.0.0.1:$PuertoWeb)."
} finally {
    if ($server) { Stop-Process -Id $server.Id -ErrorAction SilentlyContinue }
    if ($created) {
        & $php @options tests/backend-fixtures.php cleanup
        if ($LASTEXITCODE -ne 0) { Write-Error 'No se completo la limpieza; conserva tmp/fase03-fixtures.json y revisa antes de repetir.' }
    }
    if ($tunnel) { Stop-Process -Id $tunnel.Id -ErrorAction SilentlyContinue }
    $env:DB_HOST = $old.DB_HOST; $env:DB_PORT = $old.DB_PORT; $env:DB_PASSWORD = $old.DB_PASSWORD
    $env:TIENDALAB_TEST_PHP = $old.PHP; $env:TIENDALAB_TEST_PHP_OPTIONS = $old.OPT; $env:TIENDALAB_PROTOTIPO = $old.PROTO
    Pop-Location
}
