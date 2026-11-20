<article class="product-card" data-product-card data-search="<?= e($product['name'] . ' ' . $product['description']) ?>" data-id="<?= e($product['id']) ?>" data-cents="<?= e($product['cents']) ?>" data-stock="<?= e($product['stock']) ?>" data-name="<?= e($product['name']) ?>" data-image="<?= e($product['image']) ?>">
    <img class="product-image" src="/assets/img/<?= e($product['image']) ?>" width="480" height="320" alt="Imagen de demostración de <?= e($product['name']) ?>">
    <div class="product-body">
        <h3><?= e($product['name']) ?></h3><p><?= e($product['description']) ?></p>
        <div class="price-row"><strong><?= money($product['cents']) ?></strong><span class="badge <?= $product['stock'] < 10 ? 'warning' : '' ?>"><?= e($product['stock']) ?> disponibles</span></div>
        <?php if ($role === 'comprador'): ?>
        <div class="product-actions"><div class="quantity"><button type="button" data-step="-1" aria-label="Reducir cantidad de <?= e($product['name']) ?>">−</button><input aria-label="Cantidad de <?= e($product['name']) ?>" type="number" min="1" max="<?= e($product['stock']) ?>" step="1" value="1"><button type="button" data-step="1" aria-label="Aumentar cantidad de <?= e($product['name']) ?>">+</button></div><button type="button" data-add>Agregar</button></div>
        <?php else: ?><a class="button secondary wide" href="/login.php">Inicia sesión para comprar</a><?php endif; ?>
    </div>
</article>
