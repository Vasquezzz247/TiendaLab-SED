<?php
declare(strict_types=1);
// Solo para php -S; Apache tendrá su configuración propia en fase 5.
$path = rawurldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '');
if (str_contains($path, "\0")) { http_response_code(404); exit('No encontrado.'); }
$routes = ['/' => 'index.php', '/index.php' => 'index.php', '/login.php' => 'login.php', '/register.php' => 'register.php', '/prototipo/' => 'prototipo/index.php', '/prototipo/index.php' => 'prototipo/index.php'];
foreach (['logout','carrito','factura','historial','vendedor','admin-productos','admin-usuarios','imagen'] as $page) { $routes['/' . $page . '.php'] = $page . '.php'; }
if (isset($routes[$path])) {
    require __DIR__ . '/../public/' . $routes[$path];
    return true;
}
$root = realpath(__DIR__ . '/../public/assets');
$file = realpath(__DIR__ . '/../public' . $path);
if (str_starts_with($path, '/assets/') && $file !== false && is_file($file)
    && str_starts_with($file, $root . DIRECTORY_SEPARATOR)
    && in_array(strtolower(pathinfo($file, PATHINFO_EXTENSION)), ['css','js','svg','png','jpg','webp'], true)) {
    return false;
}
http_response_code(404);
header('Content-Type: text/plain; charset=UTF-8');
header('X-Content-Type-Options: nosniff');
echo 'No encontrado.';
return true;
