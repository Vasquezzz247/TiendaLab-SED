<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { exit(1); }
$path = __DIR__ . '/../.env';
$file = @fopen($path, 'x');
if ($file === false) { fwrite(STDERR, ".env ya existe o no se puede crear; no se sobrescribe.\n"); exit(1); }
chmod($path, 0600);
fwrite($file, 'DB_ROOT_PASSWORD=' . bin2hex(random_bytes(32)) . "\nDB_PASSWORD=" . bin2hex(random_bytes(32)) . "\n");
fclose($file);
echo ".env creado con secretos locales aleatorios; no versionarlo.\n";
