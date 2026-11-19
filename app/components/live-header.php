<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title><?= e($title) ?> · TiendaLab</title><link rel="icon" href="/assets/img/marca.svg" type="image/svg+xml"><link rel="stylesheet" href="/assets/css/styles.css"><script defer src="/assets/js/live.js"></script></head>
<body data-role="<?= e($role) ?>"><a class="skip-link" href="#contenido">Saltar al contenido</a>
<header class="site-header"><div class="container header-inner"><a class="brand" href="/"><img src="/assets/img/marca.svg" width="34" height="34" alt=""><span>Tienda<strong>Lab</strong></span></a><nav aria-label="Navegación principal"><a href="/">Catálogo</a>
<?php if ($role === 'comprador'): ?><a href="/historial.php">Mis facturas</a><a href="/carrito.php">Carrito <span class="count"><?= e(array_sum($_SESSION['cart'] ?? [])) ?></span></a><?php endif; ?>
<?php if ($role === 'vendedor'): ?><a href="/vendedor.php">Mis productos</a><?php endif; ?>
<?php if ($role === 'administrador'): ?><a href="/admin-productos.php">Administración</a><?php endif; ?>
<?php if ($user): ?><span class="identity"><span class="avatar"><?= e(mb_substr($user['nombre'], 0, 1)) ?></span><span><b><?= e($user['nombre']) ?></b><small><?= e(ucfirst($role)) ?></small></span></span><form method="post" action="/logout.php"><?= csrf_field() ?><button class="secondary small">Salir</button></form>
<?php else: ?><a class="button secondary small" href="/login.php">Iniciar sesión</a><a class="button small" href="/register.php">Crear cuenta</a><?php endif; ?></nav></div></header>
<div class="demo-bar"><div class="container"><span><b>Laboratorio académico</b> · Usa datos ficticios. Las operaciones se guardan en MariaDB.</span></div></div>
<main class="container main-content" id="contenido"><?php if ($flash): ?><p class="notice" role="status"><?= e($flash) ?></p><?php endif; ?>
