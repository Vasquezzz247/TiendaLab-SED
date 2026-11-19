<?php
declare(strict_types=1);
require_once __DIR__ . '/database.php';

function catalog(string $search = ''): array
{
    // LOCATE busca texto literal: %, _ y comillas no alteran la consulta.
    return rows('SELECT * FROM productos WHERE activo=1 AND (? = ? OR LOCATE(?,nombre)>0 OR LOCATE(?,descripcion)>0) ORDER BY id', [$search, '', $search, $search]);
}
function cart_items(array $cart): array
{
    $items = [];
    foreach ($cart as $id => $quantity) {
        $p = row('SELECT * FROM productos WHERE id=?', [$id]);
        if ($p) { $p['quantity'] = $quantity; $items[] = $p; }
    }
    return $items;
}
function cart_change(array &$cart, array $input): void
{
    $id = integer_input($input['id'] ?? '');
    if (($input['action'] ?? '') === 'remove') { unset($cart[$id]); return; }
    $qty = integer_input($input['cantidad'] ?? '', 1, 999);
    $product = row('SELECT stock,activo FROM productos WHERE id=?', [$id]);
    if (!$product || !$product['activo']) { throw new AppError('Producto no disponible.', 409); }
    $next = ($input['action'] ?? '') === 'add' ? ($cart[$id] ?? 0) + $qty : $qty;
    if ($next > (int) $product['stock'] || $next > 999) { throw new AppError('Existencias insuficientes para esa cantidad.', 409); }
    if (!isset($cart[$id]) && count($cart) >= 20) { throw new AppError('El carrito admite hasta 20 productos distintos.'); }
    $cart[$id] = $next;
}

function purchase(int $buyerId, array $cart): int
{
    if (!$cart || count($cart) > 20) { throw new AppError('El carrito está vacío o supera el límite.'); }
    $checked = [];
    foreach ($cart as $id => $qty) { $checked[integer_input($id)] = integer_input($qty, 1, 999); }
    ksort($checked, SORT_NUMERIC); // Mismo orden para evitar ciclos de bloqueo entre compras.
    $db = db();
    $db->begin_transaction();
    try {
        $buyer = row('SELECT id,activo,rol FROM usuarios WHERE id=? FOR UPDATE', [$buyerId]);
        if (!$buyer || !$buyer['activo'] || $buyer['rol'] !== 'comprador') { throw new AppError('Comprador no habilitado.', 403); }
        $subtotal = 0;
        $items = [];
        foreach ($checked as $id => $qty) {
            $product = row('SELECT id,nombre,precio,stock,activo FROM productos WHERE id=? FOR UPDATE', [$id]);
            if (!$product || !$product['activo'] || (int) $product['stock'] < $qty) { throw new AppError('Existencias insuficientes o producto retirado. Revisa el carrito.', 409); }
            $subtotal += cents($product['precio']) * $qty;
            if ($subtotal > 800000000000) { throw new AppError('El total supera el límite permitido.'); }
            sql('UPDATE productos SET stock=stock-? WHERE id=? AND stock>=?', [$qty, $id, $qty]);
            if ($db->affected_rows !== 1) { throw new AppError('Las existencias cambiaron. Reintenta la compra.', 409); }
            $items[] = [$id, $product['nombre'], $qty, $product['precio']];
        }
        sql('INSERT INTO facturas(comprador_id,subtotal) VALUES(?,?)', [$buyerId, decimal($subtotal)]);
        $invoiceId = $db->insert_id;
        foreach ($items as $item) {
            sql('INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES(?,?,?,?,?)', [$invoiceId, ...$item]);
        }
        $db->commit();
        return $invoiceId;
    } catch (Throwable $error) { $db->rollback(); throw $error; }
}
// VULNERABILIDAD A (aprobada en la propuesta, IDOR en factura.php?id=): esta consulta individual NO comprueba que la
// factura pertenezca al comprador autenticado. Es la única omisión intencional del proyecto. El resto sigue protegido:
// la ruta exige sesión y rol comprador (app/web.php), el historial filtra por comprador_id, el id se valida como
// entero y la consulta es preparada (no hay inyección SQL). Corrección: añadir "AND f.comprador_id=?" con el id de sesión.
function invoice_detail(int $invoiceId): array
{
    $invoice = row('SELECT f.*,u.nombre,u.correo FROM facturas f JOIN usuarios u ON u.id=f.comprador_id WHERE f.id=?', [$invoiceId]);
    if (!$invoice) { throw new AppError('Factura no encontrada.', 404); }
    $invoice['items'] = rows('SELECT * FROM detalle_facturas WHERE factura_id=? ORDER BY id', [$invoiceId]);
    return $invoice;
}
