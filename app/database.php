<?php
declare(strict_types=1);

// Solo carga la configuración de la aplicación; nunca usa DB_ROOT_PASSWORD.
function app_env(string $key, string $default = ''): string
{
    $value = getenv($key);
    if ($value !== false) { return $value; }
    static $local;
    if ($local === null) {
        $local = [];
        $file = __DIR__ . '/../.env';
        foreach (is_file($file) ? file($file, FILE_IGNORE_NEW_LINES) : [] as $line) {
            if (preg_match('/^(DB_PASSWORD|DB_HOST|DB_PORT)=(.*)$/', $line, $m)) {
                $local[$m[1]] = trim($m[2]);
            }
        }
    }
    return $local[$key] ?? $default;
}

function db(): mysqli
{
    static $connection;
    if (!$connection) {
        $password = app_env('DB_PASSWORD');
        if ($password === '' || str_starts_with($password, 'REEMPLAZAR_')) {
            throw new RuntimeException('Configuración local ausente');
        }
        mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
        $connection = new mysqli(app_env('DB_HOST', '127.0.0.1'), 'tiendalab_app', $password, 'tiendalab', (int) app_env('DB_PORT', '3306'));
        $connection->set_charset('utf8mb4');
        $connection->query("SET time_zone = '-06:00'");
    }
    return $connection;
}

// execute_query prepara, enlaza parámetros y ejecuta (PHP >= 8.2).
function sql(string $query, array $params = []): mysqli_result|bool
{
    return db()->execute_query($query, $params);
}
function rows(string $query, array $params = []): array { return sql($query, $params)->fetch_all(MYSQLI_ASSOC); }
function row(string $query, array $params = []): ?array { return sql($query, $params)->fetch_assoc(); }

class AppError extends RuntimeException
{
    public function __construct(string $message, public readonly int $status = 422) { parent::__construct($message); }
}
function text_input(array $input, string $key, int $max, bool $required = true): string
{
    $value = $input[$key] ?? '';
    if (!is_string($value) || !mb_check_encoding($value, 'UTF-8')) { throw new AppError('Entrada no válida.'); }
    $value = trim($value);
    if (($required && $value === '') || mb_strlen($value) > $max || preg_match('/[\x00-\x08\x0B\x0C\x0E-\x1F]/', $value)) {
        throw new AppError('Revisa los campos y sus longitudes.');
    }
    return $value;
}
function integer_input(mixed $value, int $min = 1, int $max = 2147483647): int
{
    if ((!is_string($value) && !is_int($value)) || !preg_match('/^(0|[1-9][0-9]{0,9})$/D', (string) $value)
        || (int) $value < $min || (int) $value > $max) { throw new AppError('Cantidad o identificador no válido.'); }
    return (int) $value;
}
function cents(string $decimal): int
{
    if (!preg_match('/^([0-9]{1,10})(?:\.([0-9]{1,2}))?$/D', $decimal, $m)) { throw new AppError('Precio no válido.'); }
    return (int) $m[1] * 100 + (int) str_pad($m[2] ?? '', 2, '0');
}
function decimal(int $cents): string { return intdiv($cents, 100) . '.' . str_pad((string) ($cents % 100), 2, '0', STR_PAD_LEFT); }
function email_input(array $input): string
{
    $email = strtolower(text_input($input, 'correo', 190));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) { throw new AppError('Correo no válido.'); }
    return $email;
}
function password_input(array $input, bool $required = true): string
{
    $password = $input['password'] ?? '';
    if (!is_string($password) || str_contains($password, "\0") || ($password !== '' && (strlen($password) < 12 || strlen($password) > 72)) || ($required && $password === '')) {
        throw new AppError('La contraseña debe tener entre 12 y 72 bytes.');
    }
    return $password;
}
function storage_dir(string $name): string
{
    $path = __DIR__ . '/../storage/' . $name;
    if (!is_dir($path) && !mkdir($path, 0700, true) && !is_dir($path)) { throw new RuntimeException('Almacenamiento no disponible'); }
    return $path;
}
