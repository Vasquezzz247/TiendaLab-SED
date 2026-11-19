# Exportación limpia de TiendaLab. Ejemplos:
#   .\scripts\exportar.ps1            ZIP del código (solo lo versionado) auditado
#   .\scripts\exportar.ps1 -Offline   paquete aparte con la imagen Docker de MariaDB
# Nunca incluye .env, sesiones, tmp/, storage/, tools/ ni .git: el ZIP sale de `git archive`
# (solo archivos versionados del commit indicado) y se audita antes de entregarlo.
param(
    [switch]$Offline,
    [string]$Ref = 'HEAD',
    [switch]$PermitirArbolSucio
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
function Invoke-Native([scriptblock]$Command, [string]$Message) {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw $Message }
}
function Write-Utf8([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}
try {
    $commit = (& git rev-parse --verify "$Ref^{commit}" 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $commit) { throw "Referencia Git no válida: $Ref" }
    $short = (& git rev-parse --short=7 $commit).Trim()
    $dist = Join-Path $root 'dist'
    New-Item -ItemType Directory -Force $dist | Out-Null

    if (-not $PermitirArbolSucio) {
        $dirty = & git status --porcelain
        if ($dirty) {
            Write-Warning 'Hay cambios sin confirmar; la exportación solo incluye lo ya versionado en el commit indicado:'
            $dirty | Select-Object -First 10 | ForEach-Object { Write-Warning "  $_" }
            throw 'Confirma (commit) o descarta los cambios, o usa -PermitirArbolSucio si es intencional.'
        }
    }

    if (-not $Offline) {
        $zip = Join-Path $dist "TiendaLab-$short-codigo.zip"
        if (Test-Path $zip) { Remove-Item $zip -Force }
        Invoke-Native { & git archive --format=zip --prefix=TiendaLab-SED/ --output $zip $commit } 'git archive falló'
        & python -I (Join-Path $PSScriptRoot 'auditar-zip.py') $zip --output (Join-Path $dist "TiendaLab-$short-codigo.auditoria.json")
        if ($LASTEXITCODE -ne 0) {
            Remove-Item $zip -Force
            throw 'La auditoría encontró hallazgos: el ZIP se eliminó y no debe entregarse.'
        }
        $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        Write-Utf8 (Join-Path $dist "TiendaLab-$short-codigo.zip.sha256") "$hash  TiendaLab-$short-codigo.zip`n"
        Write-Output "OK: $zip"
        Write-Output "SHA-256: $hash"
        return
    }

    # Paquete offline: solo la imagen pública de MariaDB fijada en compose.yaml; sin secretos ni datos.
    $compose = Get-Content (Join-Path $root 'compose.yaml') -Raw
    $match = [regex]::Match($compose, 'mariadb@sha256:[0-9a-f]{64}')
    if (-not $match.Success) { throw 'No se encontró la imagen de MariaDB fijada por digest en compose.yaml' }
    $image = $match.Value
    & docker image inspect $image 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Invoke-Native { & docker pull $image } 'No se pudo descargar la imagen de MariaDB' }
    $tag = 'tiendalab-mariadb:11.4.13'
    Invoke-Native { & docker tag $image $tag } 'docker tag falló'
    $folder = Join-Path $dist "TiendaLab-$short-offline"
    if (Test-Path $folder) { Remove-Item $folder -Recurse -Force }
    New-Item -ItemType Directory $folder | Out-Null
    $tar = Join-Path $folder 'tiendalab-mariadb.tar'
    Invoke-Native { & docker save --output $tar $tag } 'docker save falló'
    $hash = (Get-FileHash $tar -Algorithm SHA256).Hash.ToLower()
    Write-Utf8 (Join-Path $folder 'SHA256SUMS.txt') "$hash  tiendalab-mariadb.tar`n"
    $readme = @"
TiendaLab - paquete offline (solo la imagen publica de MariaDB; no contiene secretos, datos ni codigo)

Imagen: $image
Etiqueta local: $tag
Commit del proyecto asociado: $commit

En la VM (con Docker instalado), comandos RECOMENDADOS:
  sha256sum -c SHA256SUMS.txt
  docker load -i tiendalab-mariadb.tar
  php scripts/preparar-entorno.php            # crea .env local con secretos nuevos
  MARIADB_IMAGE=tiendalab-mariadb:11.4.13 docker compose up -d --pull never --wait

Tambien hacen falta los paquetes de Ubuntu (Apache, PHP, Docker): se preparan en la fase de despliegue.
La exportacion de la imagen no incluye el volumen: una VM nueva se inicializa con el seed ficticio.
"@
    Write-Utf8 (Join-Path $folder 'LEEME-OFFLINE.txt') ($readme -replace "`r`n", "`n")
    Write-Output "OK: $folder"
    Get-ChildItem $folder | ForEach-Object { '{0}  {1:N1} MB' -f $_.Name, ($_.Length / 1MB) }
    Write-Output "SHA-256 del tar: $hash"
} finally { Pop-Location }
