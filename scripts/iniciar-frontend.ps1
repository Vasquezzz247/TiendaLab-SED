param([int]$Port = 8000, [switch]$SinPrototipo, [switch]$Prototipo)
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
    $env:TIENDALAB_PROTOTIPO = if ($Prototipo -and -not $SinPrototipo) { '1' } else { '0' }
    Write-Host "TiendaLab: http://127.0.0.1:$Port/"
    Write-Host 'Aplicacion local. Requiere MariaDB iniciada y .env. Ctrl+C para detener. No inicia Apache ni Docker.'
    $phpOptions=@('-d','display_errors=0','-d','upload_max_filesize=2M','-d','post_max_size=3M')
    if(Test-Path (Join-Path $projectRoot 'tools/php/ext')) {
        $phpOptions+=@('-d',"extension_dir=$projectRoot/tools/php/ext",'-d','extension=mysqli','-d','extension=fileinfo','-d','extension=gd','-d','extension=mbstring')
    }
    & $phpPath @phpOptions -S "127.0.0.1:$Port" -t (Join-Path $projectRoot 'public') (Join-Path $projectRoot 'scripts/router.php')
} finally { $env:TIENDALAB_PROTOTIPO = $previousPrototype }
