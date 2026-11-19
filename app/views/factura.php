<?php
$number = (int) ($_GET['ejemplo'] ?? 4);
$invoice = $demo['invoices'][$number];
$subtotal = 0;
foreach ($invoice['items'] as $id => $qty) { $subtotal += $products[$id - 1]['cents'] * $qty; }
$tax = (int) round($subtotal * 13 / 100);
?>
<div class="page-heading print-hide"><a href="<?= e(demo_url('historial')) ?>">Mis facturas</a><button class="secondary" type="button" id="print-invoice">Imprimir / PDF</button></div>
<article class="invoice panel"><div class="invoice-top"><div><span class="brand"><img src="/assets/img/marca.svg" width="32" height="32" alt=""><span>Tienda<strong>Lab</strong></span></span><p>San Salvador, El Salvador<br>facturacion@tiendalab.test</p></div><div class="invoice-number"><span class="eyebrow">FACTURA DE EJEMPLO</span><h1>#<?= e(str_pad((string)$number, 5, '0', STR_PAD_LEFT)) ?></h1><p><?= e($invoice['date']) ?></p></div></div>
<div class="invoice-client"><span class="muted">Facturado a</span><strong>Ana Martínez</strong><span>ana@tiendalab.test</span></div>
<div class="table-scroll"><table><caption class="sr-only">Detalle de factura de ejemplo</caption><thead><tr><th>Producto</th><th class="number">Cant.</th><th class="number">Precio</th><th class="number">Total</th></tr></thead><tbody><?php foreach ($invoice['items'] as $id => $qty): $product = $products[$id - 1]; ?><tr><td><?= e($product['name']) ?></td><td class="number"><?= e($qty) ?></td><td class="number"><?= money($product['cents']) ?></td><td class="number"><?= money($product['cents'] * $qty) ?></td></tr><?php endforeach; ?></tbody></table></div>
<dl class="invoice-totals"><div><dt>Subtotal</dt><dd><?= money($subtotal) ?></dd></div><div><dt>IVA (13 %)</dt><dd><?= money($tax) ?></dd></div><div class="total"><dt>Total</dt><dd><?= money($subtotal + $tax) ?></dd></div></dl><p class="invoice-disclaimer">DEMOSTRACIÓN · Documento ficticio, sin validez fiscal.<br>No acredita una compra realizada.</p></article>
