<?php
declare(strict_types=1);
require_once __DIR__ . '/database.php';

function start_session(): void
{
    ini_set('session.use_strict_mode', '1');
    ini_set('session.use_only_cookies', '1');
    ini_set('session.use_trans_sid', '0');
    session_name('TiendaLabSID');
    session_save_path(storage_dir('sessions'));
    session_set_cookie_params(['lifetime' => 0, 'path' => '/', 'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off', 'httponly' => true, 'samesite' => 'Lax']);
    if (!session_start()) { throw new RuntimeException('Sesión no disponible'); }
    if (isset($_SESSION['uid']) && (time() - ($_SESSION['seen'] ?? 0) > 1800 || time() - ($_SESSION['born'] ?? 0) > 28800)) {
        $_SESSION = [];
        session_regenerate_id(true);
    }
    $_SESSION['seen'] = time();
    $_SESSION['csrf'] ??= bin2hex(random_bytes(32));
}
function csrf(): string { return $_SESSION['csrf']; }
function csrf_field(): string { return '<input type="hidden" name="csrf" value="' . e(csrf()) . '">'; }
function check_csrf(): void
{
    if (!isset($_POST['csrf']) || !is_string($_POST['csrf']) || !hash_equals(csrf(), $_POST['csrf'])) {
        throw new AppError('Solicitud no válida. Recarga el formulario.', 403);
    }
}
function current_user(): ?array
{
    if (!isset($_SESSION['uid'])) { return null; }
    $user = row('SELECT id,nombre,correo,rol,activo,password_hash FROM usuarios WHERE id=?', [$_SESSION['uid']]);
    if (!$user || !$user['activo'] || !hash_equals($_SESSION['stamp'] ?? '', hash('sha256', $user['password_hash']))) {
        $_SESSION = [];
        session_regenerate_id(true);
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
        return null;
    }
    unset($user['password_hash']);
    return $user;
}
function redirect(string $path): never { header('Location: ' . $path, true, 303); exit; }
function role_home(string $role): string
{
    return match ($role) { 'administrador' => '/admin-productos.php', 'vendedor' => '/vendedor.php', default => '/' };
}
function require_role(?array $user, string $role): array
{
    if (!$user) { redirect('/login.php'); }
    if ($user['rol'] !== $role) { throw new AppError('No tienes permiso para esta sección.', 403); }
    return $user;
}
function sign_in(array $user): void
{
    $_SESSION = [];
    session_regenerate_id(true);
    $_SESSION = ['uid' => (int) $user['id'], 'stamp' => hash('sha256', $user['password_hash']),
        'born' => time(), 'seen' => time(), 'csrf' => bin2hex(random_bytes(32)), 'cart' => []];
}
function sign_out(): void
{
    $_SESSION = [];
    $p = session_get_cookie_params();
    setcookie(session_name(), '', ['expires' => time() - 3600, 'path' => '/', 'secure' => $p['secure'], 'httponly' => true, 'samesite' => 'Lax']);
    session_destroy();
}
// Ventana compartida por procesos/sesiones. No guarda correo ni IP en claro.
function throttle(string $key, int $limit, int $seconds = 900): void
{
    $file = fopen(storage_dir('limits') . '/' . hash('sha256', $key) . '.json', 'c+');
    if (!$file || !flock($file, LOCK_EX)) { throw new RuntimeException('Límite no disponible'); }
    try {
        $bucket = json_decode(stream_get_contents($file), true);
        if (!is_array($bucket) || ($bucket['until'] ?? 0) <= time()) { $bucket = ['until' => time() + $seconds, 'count' => 0]; }
        if ($bucket['count'] >= $limit) { throw new AppError('Demasiados intentos. Espera 15 minutos antes de reintentar.', 429); }
        $bucket['count']++;
        rewind($file); ftruncate($file, 0); fwrite($file, json_encode($bucket)); fflush($file);
    } finally { flock($file, LOCK_UN); fclose($file); }
}
function register_user(array $input): void
{
    $name = text_input($input, 'nombre', 100);
    $email = email_input($input);
    $password = password_input($input);
    if (($input['confirm'] ?? null) !== $password) { throw new AppError('Las contraseñas no coinciden.'); }
    try {
        sql("INSERT INTO usuarios(nombre,correo,password_hash,rol) VALUES(?,?,?,'comprador')", [$name, $email, password_hash($password, PASSWORD_DEFAULT)]);
    } catch (mysqli_sql_exception $e) {
        if ($e->getCode() === 1062) { throw new AppError('Ese correo ya está registrado.', 409); }
        throw $e;
    }
}
