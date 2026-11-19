<?php if ($role === 'publico'): ?>
<section class="hero" aria-labelledby="hero-title">
    <div class="hero-copy"><span class="hero-label">Tecnología para estudiar y trabajar</span><h1 id="hero-title">Todo lo que necesitas<br>para tu setup, en un solo lugar</h1><p>Encuentra tus próximos favoritos. Explora nuestra selección de tecnología para tu día a día.</p>
    <form class="search" data-search-form role="search"><label class="sr-only" for="search">Buscar productos</label><input id="search" type="search" placeholder="Buscar audífonos, teclados, monitores…" autocomplete="off"><button type="button" data-search-button>Buscar</button></form></div>
    <div class="hero-stats"><div><strong>9</strong><span>productos para tu setup</span></div><div><strong>13%</strong><span>IVA desglosado en factura</span></div><div><strong>A tu ritmo</strong><span>Explora el catálogo</span></div></div>
</section>
<?php else: ?>
<div class="page-heading"><div><span class="eyebrow">ELIGE TUS FAVORITOS</span><h1>Catálogo de productos</h1></div><a class="button secondary" href="<?= e(demo_url('carrito')) ?>">Ver carrito</a></div>
<form class="search light-search" data-search-form role="search"><label class="sr-only" for="search">Buscar productos</label><input id="search" type="search" placeholder="Buscar en el catálogo" autocomplete="off"><button type="button" data-search-button>Buscar</button></form>
<?php endif; ?>
<div class="section-heading"><h2><?= $role === 'publico' ? 'Productos destacados' : 'Todo el catálogo' ?></h2><span id="result-count" aria-live="polite">9 productos</span></div>
<div class="product-grid"><?php foreach ($products as $product) { require __DIR__ . '/../components/product-card.php'; } ?></div>
<div class="empty-state" id="search-empty" hidden><h2>No encontramos productos</h2><p>Prueba con otro nombre o limpia la búsqueda.</p><button type="button" data-clear-search>Ver todos los productos</button></div>
