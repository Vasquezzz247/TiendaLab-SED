<?php
declare(strict_types=1);
define('TIENDALAB_LIVE', true);
ini_set('display_errors', '0');
ini_set('log_errors', '1');
date_default_timezone_set('America/El_Salvador');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/shop.php';
require_once __DIR__ . '/management.php';

function live_page(string $view, string $title, ?array $user, array $data = []): void
{
    $isLive = true;
    $isPrototype = false;
    $role = $user['rol'] ?? 'publico';
    $flash = $_SESSION['flash'] ?? null;
    unset($_SESSION['flash']);
    extract($data, EXTR_SKIP);
    require __DIR__ . '/components/header.php';
    require __DIR__ . '/views/live/' . $view . '.php';
    require __DIR__ . '/components/footer.php';
}
function success(string $message, string $destination): never
{
    $_SESSION['flash'] = $message;
    redirect($destination);
}
function dispatch(string $page): void
{
    $user = null;
    try {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        if (!in_array($method, ['GET','HEAD','POST'], true)) { header('Allow: GET, HEAD, POST'); throw new AppError('Método no permitido.', 405); }
        if ($page === 'imagen') {
            if ($method === 'POST') { throw new AppError('Método no permitido.', 405); }
            $name = $_GET['id'] ?? '';
            if (!is_string($name) || !preg_match('/^[a-f0-9]{32}\.png$/D', $name)) { throw new AppError('Imagen no encontrada.', 404); }
            $path = storage_dir('uploads') . '/' . $name;
            if (!is_file($path)) { throw new AppError('Imagen no encontrada.', 404); }
            header('Content-Type: image/png');
            header('Content-Length: ' . filesize($path));
            if ($method !== 'HEAD') { readfile($path); }
            return;
        }
        start_session();
        $user = current_user();
        $required = ['carrito'=>'comprador','factura'=>'comprador','historial'=>'comprador','vendedor'=>'vendedor','admin-productos'=>'administrador','admin-usuarios'=>'administrador'];
        if (isset($required[$page])) { require_role($user, $required[$page]); }
        if ($method === 'POST') {
            if ((int) ($_SERVER['CONTENT_LENGTH'] ?? 0) > 3 * 1024 * 1024) { throw new AppError('Formulario demasiado grande.', 413); }
            check_csrf();
        }
        if ($page === 'logout') {
            if ($method !== 'POST') { header('Allow: POST'); throw new AppError('Usa el botón Salir.', 405); }
            sign_out(); redirect('/login.php');
        }
        if (in_array($page, ['login','register'], true)) {
            if ($user) { redirect(role_home($user['rol'])); }
            if ($method === 'POST') {
                if ($page === 'register') {
                    throttle('register-ip:' . ($_SERVER['REMOTE_ADDR'] ?? ''), 20);
                    register_user($_POST);
                    success('Cuenta de comprador creada. Ya puedes iniciar sesión.', '/login.php');
                }
                $email = email_input($_POST);
                $password = password_input($_POST);
                throttle('login-ip:' . ($_SERVER['REMOTE_ADDR'] ?? ''), 60);
                throttle('login-email:' . $email, 5);
                $account = row('SELECT * FROM usuarios WHERE correo=?', [$email]);
                // Hash fijo de relleno evita omitir el coste bcrypt para correos inexistentes.
                $dummy = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.';
                $verified = password_verify($password, $account['password_hash'] ?? $dummy);
                if (!$account || !$verified || !$account['activo']) { throw new AppError('Correo o contraseña incorrectos, o cuenta inactiva.', 401); }
                sign_in($account); redirect(role_home($account['rol']));
            }
            live_page('auth', $page === 'login' ? 'Iniciar sesión' : 'Registro', null, ['register'=>$page === 'register']); return;
        }
        if ($page === 'catalogo') {
            if ($method === 'POST') {
                require_role($user, 'comprador');
                if (($_POST['action'] ?? '') !== 'add') { throw new AppError('Acción no válida.'); }
                $_SESSION['cart'] ??= [];
                cart_change($_SESSION['cart'], $_POST);
                success('Producto agregado al carrito.', '/carrito.php');
            }
            $search = text_input($_GET, 'q', 120, false);
            live_page('catalogo', 'Catálogo', $user, ['products'=>catalog($search), 'search'=>$search]); return;
        }
        if ($page === 'carrito') {
            $_SESSION['cart'] ??= [];
            if ($method === 'POST') {
                $action = $_POST['action'] ?? '';
                if ($action === 'checkout') {
                    $invoice = purchase((int) $user['id'], $_SESSION['cart']);
                    $_SESSION['cart'] = [];
                    $_SESSION['csrf'] = bin2hex(random_bytes(32));
                    success('Compra registrada y existencias actualizadas.', '/factura.php?id=' . $invoice);
                }
                if (!in_array($action, ['update','remove'], true)) { throw new AppError('Acción no válida.'); }
                cart_change($_SESSION['cart'], $_POST);
                success('Carrito actualizado.', '/carrito.php');
            }
            $items = cart_items($_SESSION['cart']);
            // Un producto eliminado no permanece como una selección invisible.
            $_SESSION['cart'] = array_intersect_key($_SESSION['cart'], array_column($items, null, 'id'));
            $subtotal = array_sum(array_map(fn($p) => cents($p['precio']) * $p['quantity'], $items));
            live_page('carrito', 'Tu carrito', $user, ['items'=>$items,'subtotal'=>$subtotal,'tax'=>intdiv($subtotal * 13 + 50, 100)]); return;
        }
        if ($page === 'factura' || $page === 'historial') {
            if ($method === 'POST') { throw new AppError('Método no permitido.', 405); }
            if ($page === 'factura') {
                $invoice = buyer_invoice(integer_input($_GET['id'] ?? ''), (int) $user['id']);
                live_page('factura', 'Factura', $user, ['invoice'=>$invoice]);
            } else {
                live_page('historial', 'Mis facturas', $user, ['invoices'=>rows('SELECT f.*, (SELECT COUNT(*) FROM detalle_facturas d WHERE d.factura_id=f.id) AS lineas FROM facturas f WHERE comprador_id=? ORDER BY id DESC', [$user['id']])]);
            }
            return;
        }
        if (in_array($page, ['vendedor','admin-productos','admin-usuarios'], true)) {
            $url = '/' . $page . '.php';
            if ($method === 'POST') {
                $action = $_POST['action'] ?? '';
                if ($action === 'save') {
                    $id = $page === 'admin-usuarios' ? save_user($user, $_POST) : save_product($user, $_POST, $_FILES['imagen'] ?? null);
                    success('Cambios guardados.', $url . '?editar=' . $id);
                }
                if ($action === 'delete' && $page !== 'vendedor') {
                    $id = integer_input($_POST['id'] ?? '');
                    if ($page === 'admin-usuarios') { $message = delete_user($user, $id); }
                    else { delete_product($user, $id); $message = 'Producto eliminado; los detalles históricos se conservan.'; }
                    success($message, $url);
                }
                throw new AppError('Acción no válida.');
            }
            $edit = null;
            if (isset($_GET['editar'])) {
                $id = integer_input($_GET['editar']);
                $edit = $page === 'admin-usuarios' ? row('SELECT id,nombre,correo,rol,activo FROM usuarios WHERE id=?', [$id]) : row('SELECT * FROM productos WHERE id=?', [$id]);
                if (!$edit || ($page === 'vendedor' && (int) $edit['vendedor_id'] !== (int) $user['id'])) { throw new AppError('Registro no encontrado.', 404); }
            }
            $metrics = $page === 'vendedor' ? null : row('SELECT (SELECT COUNT(*) FROM productos) productos,(SELECT COUNT(*) FROM usuarios) usuarios,(SELECT COUNT(*) FROM facturas) facturas,(SELECT COALESCE(SUM(total),0) FROM facturas) ventas');
            if ($page === 'admin-usuarios') {
                live_page('usuarios', 'Administración de usuarios', $user, ['edit'=>$edit,'metrics'=>$metrics,'users'=>rows('SELECT id,nombre,correo,rol,activo FROM usuarios ORDER BY id'),'page'=>$page]);
            } else {
                $products = $page === 'vendedor' ? rows('SELECT * FROM productos WHERE vendedor_id=? ORDER BY id', [$user['id']]) : rows('SELECT * FROM productos ORDER BY id');
                live_page('productos', 'Gestión de productos', $user, ['edit'=>$edit,'metrics'=>$metrics,'products'=>$products,'sellers'=>rows("SELECT id,nombre FROM usuarios WHERE rol='vendedor' AND activo=1 ORDER BY nombre"),'page'=>$page]);
            }
            return;
        }
        throw new AppError('Página no encontrada.', 404);
    } catch (Throwable $error) {
        $status = $error instanceof AppError ? $error->status : 503;
        $message = $error instanceof AppError ? $error->getMessage() : 'No se pudo completar la operación. Inténtalo más tarde.';
        if (!$error instanceof AppError) { error_log('TiendaLab: ' . get_class($error) . ' código ' . $error->getCode()); }
        http_response_code($status);
        if ($status === 429) { header('Retry-After: 900'); }
        live_page('error', 'Revisa la solicitud', $user, ['message'=>$message]);
    }
}
