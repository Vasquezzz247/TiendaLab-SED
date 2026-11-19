param([int]$Port = 8000, [switch]$SinPrototipo)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$phpPath = Join-Path $projectRoot 'tools/php/php.exe'
if (-not (Test-Path -LiteralPath $phpPath)) {
    $phpCommand = Get-Command php -ErrorAction SilentlyContinue
    if (-not $phpCommand) { throw 'PHP no encontrado. Consulta README.md para preparar PHP portátil o añadir PHP al PATH.' }
    $phpPath = $phpCommand.Source
}
if ($Port -lt 1024 -or $Port -gt 65535) { throw 'Usa un puerto entre 1024 y 65535.' }
$previousPrototype = $env:TIENDALAB_PROTOTIPO
try {
    $env:TIENDALAB_PROTOTIPO = if ($SinPrototipo) { '0' } else { '1' }
    Write-Host "TiendaLab: http://127.0.0.1:$Port/"
    Write-Host 'Vista previa local. Ctrl+C para detener. No inicia Apache, Docker ni base de datos.'
    & $phpPath -S "127.0.0.1:$Port" -t (Join-Path $projectRoot 'public')
} finally { $env:TIENDALAB_PROTOTIPO = $previousPrototype }
