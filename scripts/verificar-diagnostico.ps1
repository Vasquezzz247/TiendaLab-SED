# Prueba el servicio de diagnostico (vulnerabilidad B) con Apache 2.4 REAL en un contenedor efimero.
# El contenedor se publica solo en 127.0.0.1:8081 (nunca en la red) y se elimina al terminar.
# No es la arquitectura de entrega (Apache va en Ubuntu); es un arnes de prueba de la configuracion.
param([int]$Port = 8081, [string]$Image = 'httpd:2.4')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$name = 'tiendalab-diagnostico-prueba'
$docker = (Get-Command docker -ErrorAction SilentlyContinue).Source
if (-not $docker) { $docker = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe' }
function Get-ProjectPath([string]$Relative) { (Join-Path $root $Relative) }
Push-Location $root
try {
    if (Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue) { throw "Puerto $Port ocupado; usa -Port." }
    & $docker rm -f $name 2>$null | Out-Null
    # Descargar antes de ejecutar: el progreso de `docker run` sale por stderr y cortaria el script.
    $previous = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $docker image inspect $Image *> $null
    if ($LASTEXITCODE -ne 0) { & $docker pull $Image *> $null }
    & $docker image inspect $Image *> $null
    $imageExit = $LASTEXITCODE; $ErrorActionPreference = $previous
    if ($imageExit -ne 0) { throw "No se pudo obtener la imagen $Image (se necesita internet la primera vez)" }
    & $docker run -d --name $name -p "127.0.0.1:${Port}:8081" `
        -v "$(Get-ProjectPath 'diagnostico'):/var/www/tiendalab-diagnostico:ro" `
        -v "$(Get-ProjectPath 'deploy/apache/tiendalab-diagnostico.conf'):/etc/tiendalab/tiendalab-diagnostico.conf:ro" `
        -v "$(Get-ProjectPath 'tests/apache-harness.conf'):/etc/tiendalab/harness.conf:ro" `
        -e APACHE_LOG_DIR=/usr/local/apache2/logs $Image httpd -DFOREGROUND -f /etc/tiendalab/harness.conf | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar Apache en el contenedor' }
    $ready = $false
    for ($i = 0; $i -lt 40; $i++) {
        try { $r = Invoke-WebRequest "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ready = $true; break } } catch { Start-Sleep -Milliseconds 250 }
    }
    if (-not $ready) { & $docker logs $name; throw 'Apache no respondio en el puerto de prueba' }
    $previous = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $syntax = (cmd /c "`"$docker`" exec $name httpd -t -f /etc/tiendalab/harness.conf 2>&1" | Out-String).Trim()
    $syntaxExit = $LASTEXITCODE; $ErrorActionPreference = $previous
    Write-Output "httpd -t: $syntax"
    if ($syntaxExit -ne 0) { throw 'Sintaxis de Apache invalida' }
    & node tests/diagnostico.test.cjs $Port
    if ($LASTEXITCODE -ne 0) { throw 'Fallo la suite del diagnostico' }
    Write-Output "PASS: Apache 2.4 en contenedor aislado (127.0.0.1:$Port) con la configuracion de deploy/apache."
} finally {
    & $docker rm -f $name 2>$null | Out-Null
    Pop-Location
}

