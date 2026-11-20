<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { exit(1); }
// Generador explícito; no ejecutar sobre una base existente. Solo escribe SQL.
$demo = require __DIR__ . '/../demo/datos.php';
$quote = static fn(string $s): string => "'" . str_replace("'", "''", $s) . "'";
$sql = "USE tiendalab;\nSET NAMES utf8mb4;\nSTART TRANSACTION;\n";
foreach ($demo['users'] as $user) {
    $role = ['Administrador'=>'administrador','Vendedor'=>'vendedor','Comprador'=>'comprador'][$user['role']];
    $hash = password_hash('TiendaLab-Demo-2026!', PASSWORD_BCRYPT);
    $sql .= 'INSERT INTO usuarios(id,nombre,correo,password_hash,rol) VALUES (' . $user['id'] . ',' . $quote($user['name']) . ',' . $quote($user['email']) . ',' . $quote($hash) . ',' . $quote($role) . ");\n";
}
foreach ($demo['products'] as $p) {
    $sql .= 'INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (' . $p['id'] . ',2,' . $quote($p['name']) . ',' . $quote($p['description']) . ',' . number_format($p['cents']/100,2,'.','') . ',' . $p['stock'] . ',' . $quote('/assets/img/'.$p['image']) . ");\n";
}
$sql .= "INSERT INTO facturas(id,comprador_id,fecha,subtotal) VALUES\n(1,3,'2026-11-05 10:15:00',64.89),\n(2,4,'2026-11-06 16:40:00',129.00),\n(3,3,'2026-11-10 11:09:00',138.75),\n(4,3,'2026-11-10 11:12:00',73.99);\n";
foreach ([1=>[1,3],2=>[4],3=>[4,5],4=>[1,6]] as $invoice=>$ids) {
    foreach ($ids as $id) {
        $p = $demo['products'][$id-1];
        $sql .= 'INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES (' . $invoice . ',' . $id . ',' . $quote($p['name']) . ',1,' . number_format($p['cents']/100,2,'.','') . ");\n";
    }
}
$sql .= "COMMIT;\n";
file_put_contents(__DIR__ . '/../database/init/02-seed.sql', $sql);
echo "Seed ficticio generado; los hashes tienen sal individual.\n";
