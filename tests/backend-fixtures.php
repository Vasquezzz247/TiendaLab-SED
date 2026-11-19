<?php
declare(strict_types=1);
// Exclusivamente CLI: crea y limpia datos ficticios propios; no altera el seed.
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require __DIR__ . '/../app/auth.php';
require __DIR__ . '/../app/shop.php';
require __DIR__ . '/../app/images.php';
$manifest = __DIR__ . '/../tmp/fase03-fixtures.json';
function snapshot(): string
{
    $state = [];
    foreach (['usuarios','productos','facturas','detalle_facturas'] as $table) { $state[$table] = rows("SELECT * FROM $table ORDER BY id"); }
    return hash('sha256', json_encode($state));
}
function check(bool $ok, string $label): void { if (!$ok) { throw new RuntimeException($label); } }
$mode = $argv[1] ?? '';
if ($mode === 'setup') {
    if (is_file($manifest)) { throw new RuntimeException('Existe una prueba pendiente: ejecutar cleanup antes de otra prueba.'); }
    $data = ['prefix'=>'fase03_' . bin2hex(random_bytes(6)) . '_', 'baseline'=>snapshot(), 'users'=>[], 'products'=>[]];
    $db = db(); $db->begin_transaction();
    try {
        foreach (['buyer'=>'comprador','other'=>'comprador','seller'=>'vendedor','seller2'=>'vendedor','admin'=>'administrador','inactive'=>'comprador'] as $key=>$role) {
            $email = $data['prefix'] . $key . '@tiendalab.test';
            sql('INSERT INTO usuarios(nombre,correo,password_hash,rol,activo) VALUES(?,?,?,?,?)', [$data['prefix'] . $key,$email,password_hash('Prueba-Fase03-2026!', PASSWORD_DEFAULT),$role,$key === 'inactive' ? 0 : 1]);
            $data['users'][$key] = ['id'=>$db->insert_id,'email'=>$email];
        }
        foreach (['anexo1'=>['39.99',10], 'anexo2'=>['34.00',10], 'concurrent'=>['1.00',1], 'rollback1'=>['2.00',10], 'rollback2'=>['3.00',10]] as $key=>[$price,$stock]) {
            sql("INSERT INTO productos(vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES(?,?,?,?,?,'marca.svg')", [$data['users']['seller']['id'],$data['prefix'] . $key,'Producto aislado de pruebas',$price,$stock]);
            $data['products'][$key] = $db->insert_id;
        }
        // Escribir antes del commit permite limpieza si falla la publicación del resultado.
        file_put_contents($manifest, json_encode($data, JSON_PRETTY_PRINT), LOCK_EX);
        $db->commit();
    } catch (Throwable $e) { $db->rollback(); throw $e; }
    $image=imagecreatetruecolor(8,8); imagefill($image,0,0,imagecolorallocate($image,81,66,233));
    imagepng($image,__DIR__.'/../tmp/fase03-valid.png'); imagedestroy($image);
    check(str_starts_with(row('SELECT CURRENT_USER() AS cuenta')['cuenta'], 'tiendalab_app@'), 'Cuenta SQL incorrecta');
    echo json_encode($data, JSON_UNESCAPED_UNICODE); exit;
}
if (!is_file($manifest)) { throw new RuntimeException('No hay datos de prueba registrados.'); }
$data = json_decode(file_get_contents($manifest), true, 512, JSON_THROW_ON_ERROR);
check((bool)preg_match('/^fase03_[a-f0-9]{12}_$/D',$data['prefix']), 'Prefijo no valido');
$prefix = $data['prefix'];
if ($mode === 'inspect') {
    $users=rows('SELECT id,nombre,correo,rol,activo,password_hash FROM usuarios WHERE LEFT(correo,?)=? ORDER BY id',[strlen($prefix),$prefix]);
    foreach($users as &$u){$u['hash_verificable']=password_verify('Prueba-Fase03-2026!',$u['password_hash']);unset($u['password_hash']);}unset($u);
    echo json_encode(['users'=>$users,'products'=>rows('SELECT * FROM productos WHERE LEFT(nombre,?)=? ORDER BY id',[strlen($prefix),$prefix]),
        'invoices'=>rows('SELECT f.* FROM facturas f JOIN usuarios u ON u.id=f.comprador_id WHERE LEFT(u.correo,?)=? ORDER BY f.id',[strlen($prefix),$prefix]),
        'details'=>rows('SELECT d.* FROM detalle_facturas d JOIN facturas f ON f.id=d.factura_id JOIN usuarios u ON u.id=f.comprador_id WHERE LEFT(u.correo,?)=? ORDER BY d.id',[strlen($prefix),$prefix])]); exit;
}
if ($mode === 'lock') {
    db()->begin_transaction();
    row('SELECT id FROM productos WHERE id=? FOR UPDATE',[$data['products']['rollback2']]);
    file_put_contents(__DIR__.'/../tmp/fase03-lock.ready','ready');
    usleep(4000000);
    db()->rollback(); exit;
}
if ($mode === 'transaction') {
    $buyer=$data['users']['buyer']['id'];$a=$data['products']['rollback1'];$b=$data['products']['rollback2'];
    $before=row('SELECT stock FROM productos WHERE id=?',[$a])['stock'];
    $invoices=row('SELECT COUNT(*) n FROM facturas WHERE comprador_id=?',[$buyer])['n'];
    // El primer UPDATE se ejecuta; el segundo producto rechaza cantidad y exige rollback.
    try { purchase($buyer,[$a=>1,$b=>999]); throw new RuntimeException('Se acepto stock insuficiente'); }
    catch(AppError $e){check($e->status===409,'Error inesperado');}
    check(row('SELECT stock FROM productos WHERE id=?',[$a])['stock']===$before,'Rollback de stock insuficiente fallo');
    echo "PASS: rollback tras modificar primer producto y detectar stock insuficiente en segundo.\n";
    $signal=__DIR__.'/../tmp/fase03-lock.ready'; if(is_file($signal)){unlink($signal);}
    $ext=dirname(PHP_BINARY).'/ext';
    $command=[PHP_BINARY,'-d','extension_dir='.$ext,'-d','extension=mysqli','-d','extension=mbstring',__FILE__,'lock'];
    $process=proc_open($command,[0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes);
    check(is_resource($process),'No se creo proceso de bloqueo');
    fclose($pipes[0]);
    try {
        for($i=0;$i<100 && !is_file($signal);$i++){usleep(20000);}
        check(is_file($signal),'Bloqueo no preparado');
        sql('SET SESSION innodb_lock_wait_timeout=1');
        try { purchase($buyer,[$a=>1,$b=>1]); throw new RuntimeException('Se esperaba timeout SQL'); }
        catch(mysqli_sql_exception $e){check($e->getCode()===1205,'No fue timeout SQL real');}
        check(row('SELECT stock FROM productos WHERE id=?',[$a])['stock']===$before,'Rollback tras error SQL fallo');
        check(row('SELECT COUNT(*) n FROM facturas WHERE comprador_id=?',[$buyer])['n']===$invoices,'Factura incompleta');
        echo "PASS: error SQL 1205 real despues del primer UPDATE; stock y facturas revertidos.\n";
    } finally {
        stream_get_contents($pipes[1]);$err=stream_get_contents($pipes[2]);fclose($pipes[1]);fclose($pipes[2]);
        $exit=proc_close($process);if(is_file($signal)){unlink($signal);}check($exit===0 && $err==='','Proceso de bloqueo fallo');
    }
    exit;
}
if ($mode === 'cleanup') {
    $db=db();$db->begin_transaction();
    try {
        $uploads=rows('SELECT imagen FROM productos WHERE LEFT(nombre,?)=? OR vendedor_id IN (SELECT id FROM usuarios WHERE LEFT(correo,?)=?)',[strlen($prefix),$prefix,strlen($prefix),$prefix]);
        sql('DELETE d FROM detalle_facturas d JOIN facturas f ON f.id=d.factura_id JOIN usuarios u ON u.id=f.comprador_id WHERE LEFT(u.correo,?)=?',[strlen($prefix),$prefix]);
        sql('DELETE f FROM facturas f JOIN usuarios u ON u.id=f.comprador_id WHERE LEFT(u.correo,?)=?',[strlen($prefix),$prefix]);
        sql('DELETE FROM productos WHERE LEFT(nombre,?)=? OR vendedor_id IN (SELECT id FROM usuarios WHERE LEFT(correo,?)=?)',[strlen($prefix),$prefix,strlen($prefix),$prefix]);
        sql('DELETE FROM usuarios WHERE LEFT(correo,?)=?',[strlen($prefix),$prefix]);
        check(snapshot()===$data['baseline'],'Los datos previos difieren; se revierte limpieza para investigar');
        $db->commit();
        foreach($uploads as $upload){remove_image($upload['imagen']);}
        unlink($manifest);
        echo "PASS: limpieza de fixtures y SHA-256 de todas las filas previas identico (incluye seed).\n";
    } catch(Throwable $error){$db->rollback();throw $error;}
    exit;
}
throw new RuntimeException('Modo no valido');
