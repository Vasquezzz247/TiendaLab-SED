<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="TiendaLab: proyecto universitario de Seguridad en Entornos de Desarrollo.">
    <title><?= e($title) ?> · TiendaLab</title>
    <link rel="icon" href="/assets/img/marca.svg" type="image/svg+xml">
    <link rel="stylesheet" href="/assets/css/styles.css">
    <script defer src="/assets/js/carrito.js"></script>
    <script defer src="/assets/js/app.js"></script>
</head>
<body data-role="<?= e($role) ?>">
<a class="skip-link" href="#contenido">Saltar al contenido</a>
<header class="site-header">
    <div class="container header-inner">
        <a class="brand" href="/" aria-label="TiendaLab, inicio"><img src="/assets/img/marca.svg" width="34" height="34" alt=""><span>Tienda<strong>Lab</strong></span></a>
        <nav aria-label="Navegación principal">
            <a <?= $view === 'catalogo' ? 'aria-current="page"' : '' ?> href="<?= $role === 'comprador' ? e(demo_url('comprador')) : '/' ?>">Catálogo</a>
            <?php if ($role === 'comprador'): ?>
                <a <?= in_array($view, ['historial','factura'], true) ? 'aria-current="page"' : '' ?> href="<?= e(demo_url('historial')) ?>">Mis facturas</a>
                <a <?= $view === 'carrito' ? 'aria-current="page"' : '' ?> href="<?= e(demo_url('carrito')) ?>">Carrito <span class="count" data-cart-count>0</span></a>
                <span class="identity"><span class="avatar">A</span><span><b>Ana Martínez</b><small>Comprador · ejemplo</small></span></span>
            <?php elseif ($role === 'vendedor'): ?>
                <a aria-current="page" href="<?= e(demo_url('vendedor')) ?>">Mis productos</a>
                <span class="identity"><span class="avatar">T</span><span><b>Tienda Volcán</b><small>Vendedor · ejemplo</small></span></span>
            <?php elseif ($role === 'administrador'): ?>
                <a aria-current="page" href="<?= e(demo_url('admin-productos')) ?>">Administración</a>
                <span class="identity"><span class="avatar">A</span><span><b>Administrador</b><small>Perfil de ejemplo</small></span></span>
            <?php endif; ?>
            <?php if ($isPrototype): ?>
                <a class="button secondary small" href="/">Salir del prototipo</a>
            <?php else: ?>
                <a class="button secondary small" <?= $view === 'login' ? 'aria-current="page"' : '' ?> href="/login.php">Iniciar sesión</a>
                <a class="button small" <?= $view === 'register' ? 'aria-current="page"' : '' ?> href="/register.php">Crear cuenta</a>
            <?php endif; ?>
        </nav>
    </div>
</header>
<div class="demo-bar"><div class="container"><span><b><?= $isPrototype ? 'Prototipo de interfaz' : 'Vista previa · fase 1' ?></b> · Datos ficticios. Sin cuentas, compras ni cambios reales.</span><?php if (prototype_enabled()): ?><a href="<?= e(demo_url('inicio')) ?>">Revisar pantallas</a><?php endif; ?></div></div>
<main class="container main-content" id="contenido">
<noscript><p class="notice">Activa JavaScript para probar buscador, cantidades y formularios. No se enviará ningún formulario.</p></noscript>
