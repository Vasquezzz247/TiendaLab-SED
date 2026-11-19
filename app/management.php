<?php
declare(strict_types=1);
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/images.php';

function save_product(array $actor, array $input, ?array $file): int
{
    if (!in_array($actor['rol'], ['vendedor','administrador'], true)) { throw new AppError('Acceso denegado.', 403); }
    $id = integer_input($input['id'] ?? '0', 0);
    $name = text_input($input, 'nombre', 120);
    $description = text_input($input, 'descripcion', 2000);
    $price = cents(text_input($input, 'precio', 12));
    if ($price < 1 || $price > 99999999) { throw new AppError('El precio debe estar entre 0.01 y 999999.99.'); }
    $stock = integer_input($input['stock'] ?? '', 0, 999999);
    $seller = $actor['rol'] === 'vendedor' ? (int) $actor['id'] : integer_input($input['vendedor_id'] ?? '');
    $active = integer_input($input['activo'] ?? '1', 0, 1);
    $newImage = null;
    $old = null;
    $db = db(); $db->begin_transaction();
    try {
        if ($id) {
            $old = row('SELECT * FROM productos WHERE id=? FOR UPDATE', [$id]);
            if (!$old || ($actor['rol'] === 'vendedor' && (int) $old['vendedor_id'] !== (int) $actor['id'])) { throw new AppError('Producto no encontrado.', 404); }
        }
        $owner = row("SELECT id FROM usuarios WHERE id=? AND rol='vendedor' AND activo=1", [$seller]);
        if (!$owner) { throw new AppError('Selecciona un vendedor activo.'); }
        $newImage = save_image($file);
        if (!$id && !$newImage) { throw new AppError('Selecciona una imagen para el nuevo producto.'); }
        $image = $newImage ?? $old['imagen'];
        if ($id) {
            sql('UPDATE productos SET nombre=?,descripcion=?,precio=?,stock=?,imagen=?,vendedor_id=?,activo=? WHERE id=?', [$name,$description,decimal($price),$stock,$image,$seller,$active,$id]);
        } else {
            sql('INSERT INTO productos(nombre,descripcion,precio,stock,imagen,vendedor_id,activo) VALUES(?,?,?,?,?,?,?)', [$name,$description,decimal($price),$stock,$image,$seller,$active]);
            $id = $db->insert_id;
        }
        $db->commit();
    } catch (Throwable $error) { $db->rollback(); remove_image($newImage); throw $error; }
    if ($newImage && $old) { remove_image($old['imagen']); }
    return $id;
}
function delete_product(array $actor, int $id): void
{
    if ($actor['rol'] !== 'administrador') { throw new AppError('Acceso denegado.', 403); }
    $db = db(); $db->begin_transaction();
    try {
        $product = row('SELECT imagen FROM productos WHERE id=? FOR UPDATE', [$id]);
        if (!$product) { throw new AppError('Producto no encontrado.', 404); }
        // FK SET NULL conserva nombre, precio y cantidades históricos en los detalles.
        sql('DELETE FROM productos WHERE id=?', [$id]);
        $db->commit();
    } catch (Throwable $error) { $db->rollback(); throw $error; }
    remove_image($product['imagen']);
}
function save_user(array $actor, array $input): int
{
    if ($actor['rol'] !== 'administrador') { throw new AppError('Acceso denegado.', 403); }
    $id = integer_input($input['id'] ?? '0', 0);
    $name = text_input($input, 'nombre', 100);
    $email = email_input($input);
    $role = text_input($input, 'rol', 20);
    if (!in_array($role, ['comprador','vendedor','administrador'], true)) { throw new AppError('Rol no válido.'); }
    $active = integer_input($input['activo'] ?? '1', 0, 1);
    $password = password_input($input, !$id);
    if ($id === (int) $actor['id'] && ($role !== 'administrador' || !$active)) { throw new AppError('No puedes quitarte el acceso administrativo.'); }
    $db = db(); $db->begin_transaction();
    try {
        $admins = rows("SELECT id FROM usuarios WHERE rol='administrador' AND activo=1 ORDER BY id FOR UPDATE");
        $old = $id ? row('SELECT * FROM usuarios WHERE id=? FOR UPDATE', [$id]) : null;
        if ($id && !$old) { throw new AppError('Usuario no encontrado.', 404); }
        if ($old && $old['rol'] === 'administrador' && $old['activo'] && count($admins) <= 1 && ($role !== 'administrador' || !$active)) { throw new AppError('Debe permanecer un administrador activo.'); }
        $hash = $password !== '' ? password_hash($password, PASSWORD_DEFAULT) : $old['password_hash'];
        if ($id) {
            sql('UPDATE usuarios SET nombre=?,correo=?,password_hash=?,rol=?,activo=? WHERE id=?', [$name,$email,$hash,$role,$active,$id]);
        } else {
            sql('INSERT INTO usuarios(nombre,correo,password_hash,rol,activo) VALUES(?,?,?,?,?)', [$name,$email,$hash,$role,$active]);
            $id = $db->insert_id;
        }
        $db->commit(); return $id;
    } catch (Throwable $error) {
        $db->rollback();
        if ($error instanceof mysqli_sql_exception && $error->getCode() === 1062) { throw new AppError('Ese correo ya está registrado.', 409); }
        throw $error;
    }
}
function delete_user(array $actor, int $id): string
{
    if ($actor['rol'] !== 'administrador') { throw new AppError('Acceso denegado.', 403); }
    if ($id === (int) $actor['id']) { throw new AppError('No puedes eliminar tu propia cuenta administrativa.'); }
    $db = db(); $db->begin_transaction();
    try {
        $admins = rows("SELECT id FROM usuarios WHERE rol='administrador' AND activo=1 ORDER BY id FOR UPDATE");
        $user = row('SELECT id,rol,activo FROM usuarios WHERE id=? FOR UPDATE', [$id]);
        if (!$user) { throw new AppError('Usuario no encontrado.', 404); }
        if ($user['rol'] === 'administrador' && $user['activo'] && count($admins) <= 1) { throw new AppError('Debe permanecer un administrador activo.'); }
        try { sql('DELETE FROM usuarios WHERE id=?', [$id]); $message = 'Usuario eliminado.'; }
        catch (mysqli_sql_exception $error) {
            if ($error->getCode() !== 1451) { throw $error; }
            sql('UPDATE usuarios SET activo=0 WHERE id=?', [$id]);
            $message = 'Usuario desactivado: se conservan sus referencias históricas.';
        }
        $db->commit(); return $message;
    } catch (Throwable $error) { $db->rollback(); throw $error; }
}
