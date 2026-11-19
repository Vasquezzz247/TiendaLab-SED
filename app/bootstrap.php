<?php
declare(strict_types=1);

// Fase 1: renderizado de datos ficticios. No hay sesiones ni acceso a una base.
header('Content-Type: text/html; charset=UTF-8');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');
header("Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' blob:; connect-src 'none'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'");
header('Cache-Control: no-store');

if (!in_array($_SERVER['REQUEST_METHOD'] ?? 'GET', ['GET', 'HEAD'], true)) {
    http_response_code(405);
    header('Allow: GET, HEAD');
    exit('Prototipo de lectura: no se reciben formularios ni se guardan datos.');
}

function e(string|int|float $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function money(int $cents): string
{
    return '$' . number_format($cents / 100, 2, '.', ',');
}

function prototype_enabled(): bool
{
    // Una variable de entorno y loopback: nunca aceptar cabeceras de proxy como IP.
    return getenv('TIENDALAB_PROTOTIPO') === '1'
        && in_array($_SERVER['REMOTE_ADDR'] ?? '', ['127.0.0.1', '::1'], true);
}

function demo_url(string $view): string
{
    return '/prototipo/?vista=' . rawurlencode($view);
}

function render_page(string $view, string $title, string $role = 'publico'): void
{
    $demo = require __DIR__ . '/../demo/datos.php';
    $products = $demo['products'];
    $isPrototype = $role !== 'publico';
    require __DIR__ . '/components/header.php';
    require __DIR__ . '/views/' . $view . '.php'; // Solo recibe constantes de las rutas.
    require __DIR__ . '/components/footer.php';
}
