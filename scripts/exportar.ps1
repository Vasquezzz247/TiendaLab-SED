# Exportación limpia de TiendaLab. Ejemplos:
#   .\scripts\exportar.ps1                    ZIP del código (solo lo versionado) auditado
#   .\scripts\exportar.ps1 -Offline           paquete aparte con la imagen Docker de MariaDB
#   .\scripts\exportar.ps1 -Kit [-Iso <ruta>] kit de entrega completo (ZIP + offline + sumas + instrucciones [+ ISO])
# Nunca incluye .env, sesiones, tmp/, storage/, tools/ ni .git: el ZIP sale de `git archive`
# (solo archivos versionados del commit indicado) y se audita antes de entregarlo.
param(
    [switch]$Offline,
    [switch]$Kit,
    [string]$Iso,
    [string]$Ref = 'HEAD',
    [switch]$PermitirArbolSucio
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$isoSha256 = '97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8'  # ubuntu-24.04.5-live-server-amd64.iso (oficial)
Push-Location $root
function Invoke-Native([scriptblock]$Command, [string]$Message) {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw $Message }
}
function Write-Utf8([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}
function New-CodeZip([string]$Folder, [string]$Short, [string]$Commit) {
    $zip = Join-Path $Folder "TiendaLab-$Short-codigo.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Invoke-Native { & git archive --format=zip --prefix=TiendaLab-SED/ --output $zip $Commit } 'git archive falló'
    & python -I (Join-Path $PSScriptRoot 'auditar-zip.py') $zip --output (Join-Path $Folder "TiendaLab-$Short-codigo.auditoria.json")
    if ($LASTEXITCODE -ne 0) {
        Remove-Item $zip -Force
        throw 'La auditoría encontró hallazgos: el ZIP se eliminó y no debe entregarse.'
    }
    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    Write-Utf8 (Join-Path $Folder "TiendaLab-$Short-codigo.zip.sha256") "$hash  TiendaLab-$Short-codigo.zip`n"
    return $zip
}
function New-MariadbTar([string]$Folder) {
    # Solo la imagen pública de MariaDB fijada en compose.yaml; sin secretos ni datos.
    $compose = Get-Content (Join-Path $root 'compose.yaml') -Raw
    $match = [regex]::Match($compose, 'mariadb@sha256:[0-9a-f]{64}')
    if (-not $match.Success) { throw 'No se encontró la imagen de MariaDB fijada por digest en compose.yaml' }
    $image = $match.Value
    $previous = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & docker image inspect $image *> $null
    $present = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $previous
    if (-not $present) { Invoke-Native { & docker pull $image } 'No se pudo descargar la imagen de MariaDB' }
    $tag = 'tiendalab-mariadb:11.4.13'
    Invoke-Native { & docker tag $image $tag } 'docker tag falló'
    $tar = Join-Path $Folder 'tiendalab-mariadb.tar'
    Invoke-Native { & docker save --output $tar $tag } 'docker save falló'
    return $tar
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

    if ($Kit) {
        # Kit de entrega: todo lo necesario para instalar SIN internet, en una sola carpeta.
        $debsSrc = Join-Path $root 'offline/debs'
        $debs = @(Get-ChildItem $debsSrc -Filter *.deb -ErrorAction SilentlyContinue)
        if ($debs.Count -lt 20) { throw "Faltan los paquetes .deb en offline/debs (hay $($debs.Count)); preparalos antes (docs/INSTALACION_UBUNTU.md, seccion 6)." }
        $folder = Join-Path $dist "TiendaLab-kit-$short"
        if (Test-Path $folder) { Remove-Item $folder -Recurse -Force }
        New-Item -ItemType Directory $folder | Out-Null
        New-Item -ItemType Directory (Join-Path $folder 'offline/debs') -Force | Out-Null
        $zip = New-CodeZip $folder $short $commit
        Copy-Item (Join-Path $debsSrc '*.deb') (Join-Path $folder 'offline/debs')
        $tarSrc = Join-Path $root 'offline/tiendalab-mariadb.tar'
        if (Test-Path $tarSrc) { Copy-Item $tarSrc (Join-Path $folder 'offline/tiendalab-mariadb.tar') }
        else { $null = New-MariadbTar (Join-Path $folder 'offline') }
        $isoName = $null
        if ($Iso) {
            if (-not (Test-Path $Iso)) { throw "No existe el ISO: $Iso" }
            if ((Get-FileHash $Iso -Algorithm SHA256).Hash.ToLower() -ne $isoSha256) { throw 'El SHA-256 del ISO no coincide con el oficial de Ubuntu 24.04.5.' }
            $isoName = Split-Path $Iso -Leaf
            Copy-Item $Iso (Join-Path $folder $isoName)
        }
        # Sumas de todos los archivos del kit (rutas relativas, formato sha256sum).
        $sums = Get-ChildItem $folder -Recurse -File | Where-Object { $_.Name -ne 'SHA256SUMS.txt' } | Sort-Object FullName | ForEach-Object {
            $rel = $_.FullName.Substring($folder.Length + 1) -replace '\\', '/'
            "$((Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower())  $rel"
        }
        Write-Utf8 (Join-Path $folder 'SHA256SUMS.txt') (($sums -join "`n") + "`n")
        $isoLine = if ($isoName) { "  $isoName   ISO de Ubuntu Server 24.04.5 (SHA-256 oficial verificado)" } else { "  (el ISO no esta en el kit: descargalo de https://releases.ubuntu.com/24.04/ y verifica su SHA-256 $isoSha256)" }
        $readme = @"
TiendaLab - KIT DE ENTREGA (commit $short). Todo lo necesario para instalar SIN internet.

Contenido:
  TiendaLab-$short-codigo.zip   proyecto limpio (sin .env, sesiones ni secretos), auditado
  offline/debs/                 $($debs.Count) paquetes .deb de Ubuntu 24.04 (Apache, PHP 8.3, Docker, UFW...)
  offline/tiendalab-mariadb.tar imagen de MariaDB 11.4 para Docker
  SHA256SUMS.txt                sumas de todos los archivos del kit
$isoLine

Pasos (resumen; guia completa en docs/INSTALACION_UBUNTU.md del proyecto):
  1. Comprobar el kit:        sha256sum -c SHA256SUMS.txt        (o Get-FileHash en Windows)
  2. Crear la VM (Windows):   descomprimir el ZIP y ejecutar
                              .\scripts\vm\crear-vm.ps1 -Iso <ISO> -IsoSha256 $isoSha256
                              (o instalar Ubuntu Server 24.04 a mano con usuario tiendalab y OpenSSH server)
  3. Copiar a la VM, dentro de ~/TiendaLab-SED: el contenido del ZIP y la carpeta offline/
  4. Instalar (un comando):   cd ~/TiendaLab-SED && sudo bash scripts/ubuntu/instalar.sh
  5. Verificar:               sudo bash scripts/ubuntu/verificar.sh   (34 comprobaciones)
  6. Abrir la tienda:         http://<IP de la VM>/   (cuentas de prueba en el README)

Seguridad: la VM solo en la red autorizada del laboratorio; nunca exponerla a internet ni abrir puertos en el router.
"@
        Write-Utf8 (Join-Path $folder 'LEEME-KIT.txt') ($readme -replace "`r`n", "`n")
        $totalMb = [math]::Round((Get-ChildItem $folder -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
        Write-Output "OK: $folder ($totalMb MB)"
        Get-ChildItem $folder | ForEach-Object { if ($_.PSIsContainer) { '  {0}/' -f $_.Name } else { '  {0}  {1:N1} MB' -f $_.Name, ($_.Length / 1MB) } }
        return
    }

    if (-not $Offline) {
        $zip = New-CodeZip $dist $short $commit
        $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        Write-Output "OK: $zip"
        Write-Output "SHA-256: $hash"
        return
    }

    # Paquete offline (solo la imagen de MariaDB).
    $folder = Join-Path $dist "TiendaLab-$short-offline"
    if (Test-Path $folder) { Remove-Item $folder -Recurse -Force }
    New-Item -ItemType Directory $folder | Out-Null
    $tar = New-MariadbTar $folder
    $hash = (Get-FileHash $tar -Algorithm SHA256).Hash.ToLower()
    Write-Utf8 (Join-Path $folder 'SHA256SUMS.txt') "$hash  tiendalab-mariadb.tar`n"
    $readme = @"
TiendaLab - paquete offline (solo la imagen publica de MariaDB; no contiene secretos, datos ni codigo)

Etiqueta local: tiendalab-mariadb:11.4.13
Commit del proyecto asociado: $commit

En la VM (con Docker instalado):
  sha256sum -c SHA256SUMS.txt
  docker load -i tiendalab-mariadb.tar

Para instalar TODO sin internet usa el kit completo: .\scripts\exportar.ps1 -Kit
La exportacion de la imagen no incluye el volumen: una VM nueva se inicializa con el seed ficticio.
"@
    Write-Utf8 (Join-Path $folder 'LEEME-OFFLINE.txt') ($readme -replace "`r`n", "`n")
    Write-Output "OK: $folder"
    Get-ChildItem $folder | ForEach-Object { '{0}  {1:N1} MB' -f $_.Name, ($_.Length / 1MB) }
    Write-Output "SHA-256 del tar: $hash"
} finally { Pop-Location }
