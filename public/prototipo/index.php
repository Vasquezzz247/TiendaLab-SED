<?php
require __DIR__ . '/../../app/bootstrap.php';
if (!prototype_enabled()) {
    http_response_code(404);
    exit('No encontrado.');
}
$routes = [
    'inicio'=>['prototipo', 'Revisión de interfaces', 'revision'],
    'comprador'=>['catalogo', 'Catálogo de comprador', 'comprador'],
    'carrito'=>['carrito', 'Tu carrito', 'comprador'],
    'factura'=>['factura', 'Factura de ejemplo', 'comprador'],
    'historial'=>['historial', 'Mis facturas', 'comprador'],
    'vendedor'=>['vendedor', 'Panel de vendedor', 'vendedor'],
    'admin-productos'=>['admin-productos', 'Administración de productos', 'administrador'],
    'admin-usuarios'=>['admin-usuarios', 'Administración de usuarios', 'administrador'],
];
$key = $_GET['vista'] ?? 'inicio';
if (!is_string($key) || !isset($routes[$key])) {
    http_response_code(404);
    exit('Vista de prototipo no encontrada.');
}
if ($key === 'factura') {
    $invoice = $_GET['ejemplo'] ?? '4';
    if (!is_string($invoice) || !in_array($invoice, ['1', '3', '4'], true)) {
        http_response_code(404);
        exit('Ejemplo de factura no encontrado.');
    }
}
render_page(...$routes[$key]);
