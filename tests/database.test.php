<?php
declare(strict_types=1);
// Prueba CLI independiente: no forma parte del backend ni es accesible por HTTP.
if (PHP_SAPI !== 'cli') { exit(1); }
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$env = parse_ini_file(__DIR__ . '/../.env', false, INI_SCANNER_RAW);
try {
    $db = new mysqli('127.0.0.1', 'tiendalab_app', $env['DB_PASSWORD'], 'tiendalab', 3306);
    $db->set_charset('utf8mb4');
    $mode = $argv[1] ?? 'test';
    if ($mode === 'mark') { $db->query("UPDATE usuarios SET nombre='Carla Persistencia Fase2' WHERE id=5"); echo "Marcador persistencia guardado.\n"; exit; }
    if ($mode === 'restore') { $db->query("UPDATE usuarios SET nombre='Carla Prueba' WHERE id=5"); echo "Nombre ficticio restaurado.\n"; exit; }
    $count = 0;
    $expect = static function (bool $ok, string $label) use (&$count): void {
        if (!$ok) { throw new RuntimeException($label); }
        $count++; echo "PASS: $label\n";
    };
    if ($mode === 'verify-marker') {
        $expect($db->query('SELECT nombre FROM usuarios WHERE id=5')->fetch_row()[0] === 'Carla Persistencia Fase2', 'Dato modificado persiste, no solo seed'); exit;
    }
    foreach (['usuarios'=>5,'productos'=>9,'facturas'=>4,'detalle_facturas'=>7] as $table=>$expected) {
        $expect((int)$db->query("SELECT COUNT(*) FROM $table")->fetch_row()[0] === $expected, "Conteo $table=$expected");
    }
    $expect((int)$db->query("SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='tiendalab'")->fetch_row()[0] === 4, 'Cuatro claves foraneas');
    foreach ($db->query('SELECT password_hash FROM usuarios') as $row) {
        $expect(password_verify('TiendaLab-Demo-2026!', $row['password_hash']), 'Hash PHP verificable de cuenta ficticia');
    }
    $expect($db->query('SELECT SUM(total) FROM facturas')->fetch_row()[0] === '459.50', 'Total facturas 459.50');
    $expect((int)$db->query('SELECT COUNT(*) FROM facturas f WHERE subtotal <> (SELECT SUM(importe) FROM detalle_facturas d WHERE d.factura_id=f.id)')->fetch_row()[0] === 0, 'Subtotales coinciden con detalles');
    $expect($db->query('SELECT GROUP_CONCAT(id ORDER BY id) FROM facturas WHERE comprador_id=3')->fetch_row()[0] === '1,3,4', 'Ana posee 1,3,4');
    $expect((int)$db->query('SELECT comprador_id FROM facturas WHERE id=2')->fetch_row()[0] === 4, 'Luis posee 2');
    $expect($db->query('SELECT total FROM facturas WHERE id=4')->fetch_row()[0] === '83.61', 'Referencia IVA 83.61');
    $stmt=$db->prepare('SELECT nombre FROM usuarios WHERE correo=?'); $email='ana@tiendalab.test'; $stmt->bind_param('s',$email); $stmt->execute();
    $expect($stmt->get_result()->fetch_row()[0] === 'Ana Martínez','mysqli preparado y UTF-8 desde host');
    foreach ([
        "UPDATE productos SET stock=-1 WHERE id=1",
        "UPDATE productos SET precio=0 WHERE id=1",
        "UPDATE productos SET vendedor_id=99999 WHERE id=1",
        "UPDATE usuarios SET correo='ana@tiendalab.test' WHERE id=4",
        "UPDATE usuarios SET rol='desconocido' WHERE id=5",
        "UPDATE detalle_facturas SET cantidad=0 WHERE id=1",
        "DELETE FROM usuarios WHERE id=3"
    ] as $sql) {
        $db->begin_transaction(); $rejected=false;
        try { $db->query($sql); } catch (mysqli_sql_exception $error) { $rejected=true; }
        finally { $db->rollback(); }
        $expect($rejected, 'Restriccion rechaza: '.$sql);
    }
    $denied=false;
    try { $db->query('CREATE TABLE prueba_permiso_no_autorizada(id INT)'); } catch (mysqli_sql_exception $error) { $denied=$error->getCode()===1142; }
    $expect($denied,'Usuario app sin permiso CREATE');
    echo "TOTAL: $count comprobaciones aprobadas.\n";
} catch (Throwable $error) {
    // No imprimir credenciales ni detalles de conexion del entorno.
    fwrite(STDERR, 'Fallo de prueba: '.get_class($error).' codigo '.$error->getCode()."\n"); exit(1);
}
