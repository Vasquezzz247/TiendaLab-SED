'use strict';

// Todo este archivo es interacción de fase 1. No hace peticiones ni autentica.
const $ = (selector, scope = document) => scope.querySelector(selector);
const $$ = (selector, scope = document) => [...scope.querySelectorAll(selector)];
const cash = cents => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(cents / 100);
let toastTimer;
function notify(message) {
    const status = $('#status');
    status.textContent = message;
    status.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { status.hidden = true; }, 6500);
}
function explain(message) {
    $('#notice-text').textContent = message;
    $('#notice-dialog').showModal();
}
$$('[data-notice]').forEach(button => button.addEventListener('click', () => explain(button.dataset.notice)));
$('[data-close-dialog]').addEventListener('click', () => $('#notice-dialog').close());

// Búsqueda local: texto, nunca HTML construido con la entrada del usuario.
const normalize = value => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
function searchProducts() {
    const query = normalize($('#search').value);
    let count = 0;
    $$('[data-product-card]').forEach(card => {
        card.hidden = !normalize(card.dataset.search).includes(query);
        if (!card.hidden) count++;
    });
    $('#result-count').textContent = `${count} ${count === 1 ? 'producto' : 'productos'}`;
    $('#search-empty').hidden = count !== 0;
}
if ($('#search')) {
    $('#search').addEventListener('input', searchProducts);
    $('[data-search-button]').addEventListener('click', searchProducts);
    $('[data-search-form]').addEventListener('submit', event => { event.preventDefault(); searchProducts(); });
    $('[data-clear-search]').addEventListener('click', () => { $('#search').value = ''; searchProducts(); $('#search').focus(); });
}

// Solo IDs/cantidades en sessionStorage. Catálogo y precios proceden de fixtures.
const storageKey = 'tiendalab.frontend.cart.v1';
const catalog = new Map($$('[data-product-card], [data-demo-product]').map(node => [Number(node.dataset.id), {
    id: Number(node.dataset.id), name: node.dataset.name, cents: Number(node.dataset.cents), stock: Number(node.dataset.stock), image: node.dataset.image
}]));
let cart = {};
let storageUnavailable = false;
try {
    const parsed = JSON.parse(sessionStorage.getItem(storageKey) || '{}');
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
        Object.entries(parsed).forEach(([id, quantity]) => {
            if (/^[1-9]$/.test(id) && Number.isInteger(quantity) && quantity > 0 && quantity <= 999999) {
                const product = catalog.get(Number(id));
                cart[id] = product ? Math.min(quantity, product.stock) : quantity;
            }
        });
    }
} catch { storageUnavailable = true; }
function saveCart() {
    try { sessionStorage.setItem(storageKey, JSON.stringify(cart)); }
    catch { storageUnavailable = true; notify('Almacenamiento no disponible: el carrito solo se conserva en esta pantalla.'); }
    updateCount();
}
function updateCount() {
    $$('[data-cart-count]').forEach(node => { node.textContent = String(Object.values(cart).reduce((sum, quantity) => sum + quantity, 0)); });
}
updateCount();
if (storageUnavailable && document.body.dataset.role === 'comprador') notify('El almacenamiento de la pestaña no está disponible. Las selecciones podrían perderse al navegar.');
function quantityControls(scope, onChange) {
    const input = $('input', scope);
    $$('[data-step]', scope).forEach(button => button.addEventListener('click', () => {
        const value = Number(input.value) + Number(button.dataset.step);
        input.value = String(Math.max(1, Math.min(Number(input.max), Number.isFinite(value) ? Math.floor(value) : 1)));
        onChange?.();
    }));
    input.addEventListener('change', () => {
        if (TiendaCart.normalizeQuantity(input.value, Number(input.max)) === null) {
            input.value = '1';
            notify('La cantidad debe ser un entero entre 1 y las existencias disponibles.');
        }
        onChange?.();
    });
}
$$('[data-product-card]').forEach(card => {
    const control = $('.quantity', card);
    if (!control) return;
    quantityControls(control);
    $('[data-add]', card).addEventListener('click', () => {
        const product = catalog.get(Number(card.dataset.id));
        const quantity = TiendaCart.normalizeQuantity($('input', control).value, product.stock);
        if (quantity === null) { $('input', control).reportValidity(); return; }
        const next = (cart[product.id] || 0) + quantity;
        if (next > product.stock) { notify(`Solo hay ${product.stock} unidades de muestra. Ya tienes ${cart[product.id] || 0} en el carrito.`); return; }
        cart[product.id] = next;
        saveCart();
        notify(`${product.name}: agregado al carrito de muestra. No se ha realizado una compra.`);
    });
});
function element(tag, text, className) {
    const node = document.createElement(tag);
    if (text !== undefined) node.textContent = text;
    if (className) node.className = className;
    return node;
}
function renderCart() {
    const lines = $('#cart-lines');
    if (!lines) return;
    lines.replaceChildren();
    const items = [];
    Object.entries(cart).forEach(([id, quantity]) => {
        const product = catalog.get(Number(id));
        if (!product) return;
        const item = { ...product, quantity };
        items.push(item);
        const row = element('div', undefined, 'cart-line');
        const img = element('img'); img.src = `/assets/img/${product.image}`; img.alt = '';
        const text = element('div'); text.append(element('h2', product.name), element('p', `${cash(product.cents)} c/u`));
        const controls = element('div', undefined, 'quantity');
        const minus = element('button', '−'); minus.type = 'button'; minus.dataset.step = '-1'; minus.setAttribute('aria-label', `Reducir cantidad de ${product.name}`);
        const input = element('input'); input.type = 'number'; input.min = '1'; input.max = String(product.stock); input.step = '1'; input.value = String(quantity); input.setAttribute('aria-label', `Cantidad de ${product.name}`);
        const plus = element('button', '+'); plus.type = 'button'; plus.dataset.step = '1'; plus.setAttribute('aria-label', `Aumentar cantidad de ${product.name}`);
        controls.append(minus, input, plus);
        const remove = element('button', '×', 'remove-item'); remove.type = 'button'; remove.setAttribute('aria-label', `Eliminar ${product.name} del carrito`);
        remove.addEventListener('click', () => { delete cart[id]; saveCart(); renderCart(); notify('Producto quitado del carrito de muestra.'); });
        quantityControls(controls, () => {
            cart[id] = Number(input.value); saveCart();
            // Conservar el foco del botón de cantidad después de actualizar.
            const active = document.activeElement === plus ? 'plus' : document.activeElement === minus ? 'minus' : 'input';
            renderCart();
            const next = $(`[data-cart-id="${id}"] .quantity`);
            if (next) (active === 'input' ? $('input', next) : $(`[data-step="${active === 'plus' ? '1' : '-1'}"]`, next)).focus();
        });
        row.dataset.cartId = id;
        row.append(img, text, controls, element('strong', cash(product.cents * quantity)), remove);
        lines.append(row);
    });
    const summary = TiendaCart.totals(items);
    $('#subtotal').textContent = cash(summary.subtotal);
    $('#tax').textContent = cash(summary.tax);
    $('#total').textContent = cash(summary.total);
    $('#cart-empty').hidden = items.length !== 0;
    $('#checkout').disabled = items.length === 0;
}
if ($('[data-cart-page]')) {
    renderCart();
    $('#load-cart-example').addEventListener('click', () => { cart = {1:1, 6:1}; saveCart(); renderCart(); notify('Ejemplo del anexo cargado. Esta selección no es una compra.'); });
    $('#reset-cart').addEventListener('click', () => { cart = {}; saveCart(); renderCart(); notify('Carrito de muestra reiniciado.'); });
}
$('#print-invoice')?.addEventListener('click', () => window.print());

// Formularios: validación local y aviso honesto, sin fetch ni envío al servidor.
const formMessages = {
    login: 'Campos revisados. El inicio de sesión aún no está implementado: no se ha autenticado a ningún usuario.',
    register: 'Campos revisados. No se ha creado ninguna cuenta. El registro con rol comprador se implementará en fase 3.',
    product: 'Borrador revisado. No se ha publicado ni modificado ningún producto o archivo.',
    user: 'Borrador revisado. No se ha creado ni modificado ninguna cuenta, contraseña o rol.'
};
$$('[data-demo-form]').forEach(form => {
    const validate = () => {
        const confirmation = $('#confirm', form);
        if (confirmation) confirmation.setCustomValidity(confirmation.value !== $('#password', form).value ? 'Las contraseñas no coinciden.' : '');
        if (!form.reportValidity()) return;
        $('.form-feedback', form).textContent = formMessages[form.dataset.demoForm];
        $$('input[type="password"]', form).forEach(input => { input.value = ''; });
    };
    form.addEventListener('submit', event => { event.preventDefault(); validate(); });
    $('[data-check-form]', form).addEventListener('click', validate);
    $('#confirm', form)?.addEventListener('input', event => event.target.setCustomValidity(''));
});
let previewUrl;
const imageInput = $('#product-image');
function resetImage() {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    previewUrl = undefined;
    if (imageInput) { imageInput.value = ''; imageInput.setCustomValidity(''); }
    const img = $('#image-preview');
    if (img) { img.hidden = true; img.removeAttribute('src'); }
}
imageInput?.addEventListener('change', () => {
    const file = imageInput.files[0];
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    imageInput.setCustomValidity('');
    $('#image-preview').hidden = true;
    if (!file) return;
    if (!['image/jpeg','image/png','image/webp'].includes(file.type) || file.size > 2 * 1024 * 1024) {
        imageInput.setCustomValidity('Elige JPG, PNG o WEBP de hasta 2 MB.'); imageInput.reportValidity(); return;
    }
    previewUrl = URL.createObjectURL(file);
    $('#image-preview').src = previewUrl;
    $('#image-preview').hidden = false;
});
function showProductForm() {
    if ($('#product-editor')) $('#product-editor').hidden = false;
    $('#product-form').scrollIntoView({ behavior: 'smooth', block: 'start' });
    $('#product-name').focus({ preventScroll: true });
}
$$('[data-new-product]').forEach(button => button.addEventListener('click', () => {
    $('#product-form').reset(); resetImage();
    $('#product-form-title').textContent = 'Nuevo producto'; $('#product-save').textContent = 'Publicar producto';
    $('.form-feedback', $('#product-form')).textContent = ''; showProductForm();
}));
$$('[data-edit-product]').forEach(button => button.addEventListener('click', () => {
    resetImage();
    $('#product-form-title').textContent = 'Editar producto · borrador';
    $('#product-name').value = button.dataset.name; $('#description').value = button.dataset.description;
    $('#price').value = Number(button.dataset.price).toFixed(2); $('#stock').value = button.dataset.stock;
    $('#image-preview').src = `/assets/img/${button.dataset.image}`; $('#image-preview').hidden = false;
    $('#product-save').textContent = 'Guardar cambios';
    $('.form-feedback', $('#product-form')).textContent = 'Revisa este borrador. No se guardan modificaciones.';
    showProductForm();
}));
$$('[data-role-preview]').forEach(select => select.addEventListener('change', () => {
    notify('Selección de rol de muestra. No cambia permisos ni guarda información.');
}));
$$('[data-edit-user]').forEach(button => button.addEventListener('click', () => {
    $('#user-form-title').textContent = 'Editar usuario · borrador';
    $('#user-name').value = button.dataset.name; $('#user-email').value = button.dataset.email; $('#user-role').value = button.dataset.role;
    $('#user-password').value = ''; $('#user-password').required = false; $('#user-password').placeholder = 'Opcional en edición';
    $('#user-save').textContent = 'Guardar cambios';
    $('.form-feedback', $('#user-form')).textContent = 'No se guardan cambios ni se modifican permisos.';
    $('#user-form').scrollIntoView({ behavior: 'smooth', block: 'start' }); $('#user-name').focus({ preventScroll: true });
}));
$('#new-user')?.addEventListener('click', () => {
    $('#user-form').reset(); $('#user-password').required = true; $('#user-password').placeholder = 'Mínimo 8 caracteres';
    $('#user-form-title').textContent = 'Nuevo usuario'; $('#user-save').textContent = 'Crear usuario';
    $('.form-feedback', $('#user-form')).textContent = ''; $('#user-name').focus();
});
