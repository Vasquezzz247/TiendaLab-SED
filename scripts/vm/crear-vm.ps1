# Crea la VM de TiendaLab en VirtualBox con Ubuntu Server 24.04 LTS (instalacion desatendida).
# Red: NAT (salida a internet y reenvio SOLO a 127.0.0.1 del anfitrion) + red solo-anfitrion (192.168.56.x).
# La VM nunca se publica en la red del Wi-Fi ni en internet. Las credenciales se generan al azar y se guardan
# FUERA del repositorio (carpeta -Carpeta); este script no imprime contrasenas.
#   .\scripts\vm\crear-vm.ps1 -Iso C:\ruta\ubuntu-24.04.5-live-server-amd64.iso
param(
    [Parameter(Mandatory)][string]$Iso,
    [string]$IsoSha256,
    [string]$Nombre = 'TiendaLab-Ubuntu2404',
    [string]$Carpeta = (Join-Path $HOME 'Downloads\TiendaLab-VM'),
    [int]$MemoriaMB = 3072,
    [int]$Cpus = 2,
    [int]$DiscoGB = 30,
    [int]$PuertoSsh = 2222, [int]$PuertoWeb = 8080, [int]$PuertoDiag = 18081
)
$ErrorActionPreference = 'Stop'
$vbox = (Get-Command VBoxManage -ErrorAction SilentlyContinue).Source
if (-not $vbox) { $vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' }
function Invoke-Vbox { & $vbox @args; if ($LASTEXITCODE -ne 0) { throw "VBoxManage fallo: $($args -join ' ')" } }
function New-Secret([int]$Length) { -join ((48..57) + (65..90) + (97..122) | Get-Random -Count $Length | ForEach-Object { [char]$_ }) }

if (-not (Test-Path $Iso)) { throw "No existe el ISO: $Iso" }
if ($IsoSha256) {
    $real = (Get-FileHash $Iso -Algorithm SHA256).Hash.ToLower()
    if ($real -ne $IsoSha256.ToLower()) { throw 'El SHA-256 del ISO no coincide con el oficial: no se continua.' }
    Write-Output "SHA-256 del ISO verificado."
}
if ((& $vbox list vms) -match [regex]::Escape("`"$Nombre`"")) { throw "Ya existe una VM llamada $Nombre; no se toca." }
New-Item -ItemType Directory -Force $Carpeta | Out-Null

# Clave SSH y contrasena de la VM, solo en la carpeta local (no en Git).
$clave = Join-Path $Carpeta 'id_tiendalab'
if (-not (Test-Path $clave)) { & ssh-keygen -q -t ed25519 -N '""' -C 'tiendalab-lab' -f $clave; if ($LASTEXITCODE -ne 0) { throw 'ssh-keygen fallo' } }
$publica = (Get-Content "$clave.pub" -Raw).Trim()
$usuario = 'tiendalab'
$credenciales = Join-Path $Carpeta 'vm-credenciales.txt'
if (-not (Test-Path $credenciales)) {
    [IO.File]::WriteAllText($credenciales, "usuario=$usuario`npassword=$(New-Secret 20)`n", (New-Object Text.UTF8Encoding($false)))
}
$password = ((Get-Content $credenciales | Where-Object { $_ -like 'password=*' }) -replace '^password=', '')

$disco = Join-Path $env:USERPROFILE "VirtualBox VMs\$Nombre\$Nombre.vdi"
Invoke-Vbox createvm --name $Nombre --ostype Ubuntu24_LTS_64 --register
Invoke-Vbox modifyvm $Nombre --memory $MemoriaMB --cpus $Cpus --vram 16 --graphicscontroller vmsvga --audio-driver none --rtc-use-utc on
Invoke-Vbox modifyvm $Nombre --nic1 nat --nic2 hostonly --hostonlyadapter2 'VirtualBox Host-Only Ethernet Adapter'
# Reenvios SOLO en 127.0.0.1 del anfitrion: ssh, tienda y diagnostico.
Invoke-Vbox modifyvm $Nombre --natpf1 "ssh,tcp,127.0.0.1,$PuertoSsh,,22"
Invoke-Vbox modifyvm $Nombre --natpf1 "web,tcp,127.0.0.1,$PuertoWeb,,80"
Invoke-Vbox modifyvm $Nombre --natpf1 "diag,tcp,127.0.0.1,$PuertoDiag,,8081"
Invoke-Vbox createmedium disk --filename $disco --size ($DiscoGB * 1024) --format VDI
Invoke-Vbox storagectl $Nombre --name SATA --add sata --controller IntelAhci
Invoke-Vbox storageattach $Nombre --storagectl SATA --port 0 --device 0 --type hdd --medium $disco

# Instalacion desatendida (autoinstall de Ubuntu). La clave publica queda autorizada para el usuario.
$post = "mkdir -p /home/$usuario/.ssh && echo '$publica' >> /home/$usuario/.ssh/authorized_keys && chmod 700 /home/$usuario/.ssh && chmod 600 /home/$usuario/.ssh/authorized_keys && chown -R ${usuario}:${usuario} /home/$usuario/.ssh"
Invoke-Vbox unattended install $Nombre --iso=$Iso --user=$usuario --password=$password --full-user-name='TiendaLab' `
    --hostname=tiendalab-srv.lab --time-zone=America/El_Salvador --locale=es_SV `
    --post-install-command=$post --start-vm=headless
Write-Output "VM $Nombre creada y arrancando la instalacion desatendida."
Write-Output "SSH (cuando termine):  ssh -i `"$clave`" -p $PuertoSsh $usuario@127.0.0.1"
Write-Output "Credenciales locales (no versionadas): $credenciales"
