<?php
declare(strict_types=1);
require __DIR__ . '/../app/bootstrap.php';
$checks = 0;
function expect(bool $condition, string $message): void
{
    global $checks;
    if (!$condition) { throw new RuntimeException($message); }
    $checks++;
}
expect(e('<tag a="x">&\'') === '&lt;tag a=&quot;x&quot;&gt;&amp;&#039;', 'Escape HTML de etiquetas y comillas');
$prior = getenv('TIENDALAB_PROTOTIPO');
try {
    putenv('TIENDALAB_PROTOTIPO=1');
    foreach (['127.0.0.1', '::1'] as $ip) {
        $_SERVER['REMOTE_ADDR'] = $ip;
        expect(prototype_enabled(), 'Loopback habilitado');
    }
    $_SERVER['REMOTE_ADDR'] = '192.0.2.10'; // Dirección reservada para documentación.
    $_SERVER['HTTP_X_FORWARDED_FOR'] = '127.0.0.1';
    expect(!prototype_enabled(), 'IP externa no puede habilitarse con cabecera de proxy');
    unset($_SERVER['REMOTE_ADDR']);
    expect(!prototype_enabled(), 'Sin dirección se deniega');
    $_SERVER['REMOTE_ADDR'] = '127.0.0.1';
    putenv('TIENDALAB_PROTOTIPO=0');
    expect(!prototype_enabled(), 'Deshabilitado en entorno');
    putenv('TIENDALAB_PROTOTIPO');
    expect(!prototype_enabled(), 'Deshabilitado por defecto');
    expect(money(8361) === '$83.61', 'Formato monetario del anexo');
} finally {
    putenv($prior === false ? 'TIENDALAB_PROTOTIPO' : 'TIENDALAB_PROTOTIPO=' . $prior);
}
echo "PASS: {$checks} comprobaciones PHP de escape, guardia local y formato monetario.\n";
