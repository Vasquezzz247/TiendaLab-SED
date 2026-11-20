param([int]$Port=8010,[int]$SecondPort=8011,[int]$UnavailablePort=8012)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$php=Join-Path $root 'tools/php/php.exe'
$options=@('-d','display_errors=0','-d','upload_max_filesize=2M','-d','post_max_size=3M')
if(Test-Path $php){$options+=@('-d',"extension_dir=$root/tools/php/ext",'-d','extension=mysqli','-d','extension=fileinfo','-d','extension=gd','-d','extension=mbstring')}
else{$php=(Get-Command php -ErrorAction Stop).Source}
$servers=@()
$previous=$env:TIENDALAB_PROTOTIPO
$oldPhp=$env:TIENDALAB_TEST_PHP
$oldOptions=$env:TIENDALAB_TEST_PHP_OPTIONS
$oldDbPort=$env:DB_PORT
$created=$false
Push-Location $root
try {
    foreach($portNumber in @($Port,$SecondPort,$UnavailablePort)){
        if(Get-NetTCPConnection -State Listen -LocalPort $portNumber -ErrorAction SilentlyContinue){throw "Puerto $portNumber ocupado; usa otro puerto."}
    }
    if(@($Port,$SecondPort,$UnavailablePort|Select-Object -Unique).Count -ne 3){throw 'Se requieren tres puertos distintos.'}
    $files=Get-ChildItem app,public,scripts,tests -Filter *.php -Recurse
    foreach($file in $files){& $php -l $file.FullName; if($LASTEXITCODE -ne 0){throw 'Sintaxis PHP invalida'}}
    & node --check public/assets/js/live.js
    if($LASTEXITCODE -ne 0){throw 'JS invalido'}
    & $php @options tests/security.test.php
    if($LASTEXITCODE -ne 0){throw 'Fallo utilidades de seguridad'}
    & node --test tests/frontend.test.cjs
    if($LASTEXITCODE -ne 0){throw 'Fallo utilidades de cantidades e IVA'}
    $setup=& $php @options tests/backend-fixtures.php setup
    if($LASTEXITCODE -ne 0){throw 'No se prepararon fixtures; revisar manifest en tmp antes de repetir'}
    $created=$true
    Write-Output 'PASS: fixtures aislados creados mediante tiendalab_app; snapshot previo guardado sin publicar filas.'
    $env:TIENDALAB_PROTOTIPO='0'
    foreach($portNumber in @($Port,$SecondPort,$UnavailablePort)){
        $env:DB_PORT=if($portNumber -eq $UnavailablePort){'1'}else{$oldDbPort}
        $servers+=Start-Process -FilePath $php -ArgumentList ($options+@('-S',"127.0.0.1:$portNumber",'-t','public','scripts/router.php')) -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput "tmp/fase03-server-$portNumber.out.log" -RedirectStandardError "tmp/fase03-server-$portNumber.err.log"
        $ready=$false
        for($i=0;$i -lt 30;$i++){
            try{$response=Invoke-WebRequest "http://127.0.0.1:$portNumber/login.php" -TimeoutSec 2; if($response.StatusCode -eq 200){$ready=$true;break}}catch{Start-Sleep -Milliseconds 100}
        }
        if(-not $ready){throw "Servidor $portNumber no disponible; revisar log local"}
    }
    $env:DB_PORT=$oldDbPort
    $env:TIENDALAB_TEST_PHP=$php
    $env:TIENDALAB_TEST_PHP_OPTIONS=ConvertTo-Json -InputObject $options -Compress
    & node tests/backend.test.cjs $Port $SecondPort $UnavailablePort
    if($LASTEXITCODE -ne 0){throw 'Fallo suite HTTP/BD'}
    & $php @options tests/backend-fixtures.php transaction
    if($LASTEXITCODE -ne 0){throw 'Fallo rollback SQL'}
    Write-Output "PASS: sintaxis de $($files.Count) archivos PHP; dos procesos HTTP concurrentes y otro con conexion no disponible."
} finally {
    foreach($server in $servers){Stop-Process -Id $server.Id -ErrorAction SilentlyContinue}
    $env:DB_PORT=$oldDbPort
    if($created){
        & $php @options tests/backend-fixtures.php cleanup
        if($LASTEXITCODE -ne 0){Write-Error 'No se completo limpieza; conservar manifest y revisar antes de repetir.'}
    }
    $env:TIENDALAB_PROTOTIPO=$previous
    $env:TIENDALAB_TEST_PHP=$oldPhp
    $env:TIENDALAB_TEST_PHP_OPTIONS=$oldOptions
    Pop-Location
}
